//
//  KeyChainManager.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 7/12/20.
//

import UIKit
import CommonCrypto

protocol KeyChainManagerType {
    func getEncryptionKey(for keyName: String, completion: @escaping ((_ key: SecKey?) -> Void))
    func encrypt(inputData: Data, with key: SecKey, completion: @escaping ((_ cipheredData: Data?) -> Void))
    func decrypt(encryptedData: Data, with key: SecKey, completion: @escaping ((_ deCipherData: Data?) -> Void))
    func savePin(for keyName: String, data: Data, completion: @escaping ((_ success: Bool) -> Void))
    func retrieveSavedPin(for keyName: String, completion: @escaping ((_ data: Data?) -> Void))
}

class KeyChainManager: KeyChainManagerType {

    private func retrieveKey(for keyName: String) -> SecKey? {
        let tag = keyName.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : tag,
            kSecAttrKeyType as String           : kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String             : true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }
        return (item as! SecKey)
    }

    private func makeAndStoreKey(for keyName: String) -> SecKey? {

        let flags: SecAccessControlCreateFlags = [.privateKeyUsage]

        let access =
            SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                            flags,
                                            nil)!

        let tag = keyName.data(using: .utf8)!
        let attributes: [String: Any] = [
            kSecAttrKeyType as String           : kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String     : 256,
            kSecAttrTokenID as String           : kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String : [
                kSecAttrIsPermanent as String       : true,
                kSecAttrApplicationTag as String    : tag,
                kSecAttrAccessControl as String     : access
            ]
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            return nil
        }

        return privateKey
    }

    func getEncryptionKey(for keyName: String, completion: @escaping ((_ key: SecKey?) -> Void)) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            completion(self?.retrieveKey(for: keyName) ?? self?.makeAndStoreKey(for: keyName))
        }
    }

    func encrypt(inputData: Data, with key: SecKey, completion: @escaping ((_ cipheredData: Data?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            guard let publicKey = SecKeyCopyPublicKey(key) else {
                completion(nil)
                return
            }
            let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
            guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
                completion(nil)
                return
            }
            var error: Unmanaged<CFError>?
            let cipheredData = SecKeyCreateEncryptedData(publicKey, algorithm,
                                                           inputData as CFData,
                                                           &error) as Data?
            guard cipheredData != nil else {
                completion(nil)
                return
            }
            completion(cipheredData)
        }
    }

    func decrypt(encryptedData: Data, with key: SecKey, completion: @escaping ((_ deCipherData: Data?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
            guard SecKeyIsAlgorithmSupported(key, .decrypt, algorithm) else {
                completion(nil)
                return
            }

            var error: Unmanaged<CFError>?
            let deCipherData = SecKeyCreateDecryptedData(key,
                                                         algorithm,
                                                         encryptedData as CFData,
                                                         &error) as Data?
            completion(deCipherData)
        }
    }

    func savePin(for keyName: String, data: Data, completion: @escaping ((_ success: Bool) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let query = [
                kSecClass as String       : kSecClassGenericPassword as String,
                kSecAttrAccount as String : keyName,
                kSecValueData as String   : data ] as [String : Any]

            SecItemDelete(query as CFDictionary)

            completion(SecItemAdd(query as CFDictionary, nil) == noErr)
        }
    }

    func retrieveSavedPin(for keyName: String, completion: @escaping ((_ data: Data?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let query = [
                kSecClass as String       : kSecClassGenericPassword,
                kSecAttrAccount as String : keyName,
                kSecReturnData as String  : kCFBooleanTrue!,
                kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

            var dataTypeRef: AnyObject? = nil

            let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
            
            if status == noErr {
                completion(dataTypeRef as! Data?)
            } else {
                completion(nil)
            }
        }
    }

}

enum KeyChainError: Error {
    case keyGenError
    case pinMismatchError
    case pinRetrievalError
    case pinSavingError
    case encryptionError
    case decryptionError
    case unknown
}

extension KeyChainError: LocalizedError {

    var errorDescription: String? {
        switch self {
            case .unknown:
                return "Unknown Error occured"
            case .keyGenError:
                return "KeyChain key cannot be generated"
            case .pinMismatchError:
                return "Pin entered did not match"
            case .pinRetrievalError:
                return "Saved Pin could not be retrieved"
            case .decryptionError:
                return "Decryption failed"
            case .encryptionError:
                return "Encryption failed"
            case .pinSavingError:
                return "Pin could not be saved"
        }
    }
}
