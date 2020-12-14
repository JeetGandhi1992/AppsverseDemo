//
//  RealmKey.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 14/12/20.
//

import Foundation

struct RealmKey {

    static func getKey(dbName: String) -> NSData? {

        // Identifier for our keychain entry - should be unique for your application
        let keychainIdentifier = "com.demo.\(dbName)"
        let keychainIdentifierData = keychainIdentifier.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        // First check in the keychain for an existing key
        var query: [NSString: AnyObject] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
            kSecAttrKeySizeInBits: 512 as AnyObject,
            kSecReturnData: true as AnyObject
        ]

        var dataTypeRef: AnyObject?

        var status = withUnsafeMutablePointer(to: &dataTypeRef) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if status == errSecSuccess {
            return dataTypeRef as? NSData
        }

        // No pre-existing key from this application, so generate a new one
        let keyData = NSMutableData(length: 64)!
        let result = SecRandomCopyBytes(kSecRandomDefault, 64, keyData.mutableBytes
                                            .bindMemory(to: UInt8.self, capacity: 64))

        if result != 0 {
            fatalError("Failed to get random bytes")
        }

        // Store the key in the keychain
        query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
            kSecAttrKeySizeInBits: 512 as AnyObject,
            kSecValueData: keyData
        ]

        status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            fatalError("Failed to insert the new key in the keychain")
        }

        return keyData
    }
}
