//
//  KeyChainHelper.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 10/12/20.
//

import UIKit
import RxSwift
import RxCocoa

protocol KeyChainHelperType {
    var secKey: SecKey? { get }
    var encryptionKeyName: String { get }
    var passwordKeyName: String { get }
    var keyChainManager: KeyChainManagerType { get }

    func setupSecKey() -> Observable<TaskUIEvent<Void>>
    func save(pin: String) -> Observable<TaskUIEvent<Void>>
    func verify(pin: String) -> Observable<TaskUIEvent<Void>>
    
    func isUserEnrolled() -> Observable<TaskUIEvent<Bool>>

    func encrypt(inputData: Data) -> Observable<TaskUIEvent<Data>>
    func decrypt(encryptedData: Data) -> Observable<TaskUIEvent<Data>>

}

class KeyChainHelper: KeyChainHelperType {
    private(set) var encryptionKeyName: String
    private(set) var passwordKeyName: String

    private(set) var secKey: SecKey?
    private(set) var keyChainManager: KeyChainManagerType


    init(encryptionKeyName: String,
         passwordKeyName: String,
         keyChainManager: KeyChainManagerType) {
        self.encryptionKeyName = encryptionKeyName
        self.passwordKeyName = passwordKeyName
        self.keyChainManager = keyChainManager
    }

    func setupSecKey() -> Observable<TaskUIEvent<Void>> {

        return Observable<TaskUIEvent<Void>>.create { [weak self] observer in
            guard let self = self else {
                observer.on(.next(TaskUIEvent.failed(KeyChainError.unknown)))
                observer.on(.completed)
                return Disposables.create()
            }
            self.keyChainManager.getEncryptionKey(for: self.encryptionKeyName) { [weak self] key in
                guard (key != nil) else {
                    observer.on(.next(TaskUIEvent.failed(KeyChainError.keyGenError)))
                    observer.on(.completed)
                    return
                }
                self?.secKey = key
                observer.on(.next(TaskUIEvent.succeeded(())))
                observer.on(.completed)

            }
            return Disposables.create()
        }.startWith(.waiting)

    }

    func save(pin: String) -> Observable<TaskUIEvent<Void>> {

        return Observable<TaskUIEvent<Void>>.create { [weak self] observer in
            guard let self = self,
                  (self.secKey != nil),
                  let pinData = pin.data(using: .utf8) else {
                observer.on(.next(TaskUIEvent.failed(KeyChainError.keyGenError)))
                observer.on(.completed)
                return Disposables.create()
            }
            self.keyChainManager.encrypt(inputData: pinData, with: self.secKey!) { [weak self] encryptedPin in
                guard let self = self,
                      (encryptedPin != nil) else {
                    observer.on(.next(TaskUIEvent.failed(KeyChainError.encryptionError)))
                    observer.on(.completed)
                    return
                }
                self.keyChainManager.savePin(for: self.passwordKeyName, data: encryptedPin!) { (success) in
                    success ? observer.on(.next(TaskUIEvent.succeeded(()))) : observer.on(.next(TaskUIEvent.failed(KeyChainError.pinSavingError)))
                    observer.on(.completed)
                }
            }
            return Disposables.create()
        }.startWith(.waiting)
    }

    func verify(pin: String) -> Observable<TaskUIEvent<Void>> {
        return Observable<TaskUIEvent<Void>>.create { [weak self] observer in
            guard let self = self,
                  (self.secKey != nil) else {
                observer.on(.next(TaskUIEvent.failed(KeyChainError.keyGenError)))
                observer.on(.completed)
                return Disposables.create()
            }
            self.keyChainManager.retrieveSavedPin(for: self.passwordKeyName) { [weak self] encryptedPinData in
                guard let self = self, (encryptedPinData != nil) else {
                    observer.on(.next(TaskUIEvent.failed(KeyChainError.pinRetrievalError)))
                    observer.on(.completed)
                    return
                }
                self.keyChainManager.decrypt(encryptedData: encryptedPinData!,
                                                                    with: self.secKey!) { (decryptedPinData) in
                    guard (decryptedPinData != nil),
                          let decryptedPin = String(data: decryptedPinData!, encoding: .utf8) else {
                        observer.on(.next(TaskUIEvent.failed(KeyChainError.decryptionError)))
                        observer.on(.completed)
                        return
                    }
                    if decryptedPin == pin {
                        observer.on(.next(TaskUIEvent.succeeded(())))
                    } else {
                        observer.on(.next(TaskUIEvent.failed(KeyChainError.pinMismatchError)))
                    }
                    observer.on(.completed)

                }
            }
            return Disposables.create()
        }.startWith(.waiting)
    }

    func isUserEnrolled() -> Observable<TaskUIEvent<Bool>> {

        return Observable<TaskUIEvent<Bool>>.create { [weak self] observer in
            guard let self = self else {
                observer.on(.next(TaskUIEvent.failed(KeyChainError.unknown)))
                observer.on(.completed)
                return Disposables.create()
            }
            self.keyChainManager.retrieveSavedPin(for: self.passwordKeyName) { key in

                guard (key != nil) else {
                    observer.on(.next(TaskUIEvent.succeeded(false)))
                    observer.on(.completed)
                    return
                }
                observer.on(.next(TaskUIEvent.succeeded(true)))
                observer.on(.completed)

            }
            return Disposables.create()
        }.startWith(.waiting)
    }

    func encrypt(inputData: Data) -> Observable<TaskUIEvent<Data>> {

        return Observable<TaskUIEvent<Data>>.create { [weak self] observer in
            guard let self = self,
                  (self.secKey != nil) else {
                observer.on(.next(TaskUIEvent.failed(KeyChainError.unknown)))
                observer.on(.completed)
                return Disposables.create()
            }
            self.keyChainManager.encrypt(inputData: inputData, with: self.secKey!) { (encryptedData) in
                guard (encryptedData != nil) else {
                    observer.on(.next(TaskUIEvent.failed(KeyChainError.encryptionError)))
                    observer.on(.completed)
                    return
                }
                observer.on(.next(TaskUIEvent.succeeded(encryptedData!)))
                observer.on(.completed)

            }
            return Disposables.create()
        }.startWith(.waiting)
    }

    func decrypt(encryptedData: Data) -> Observable<TaskUIEvent<Data>> {

        return Observable<TaskUIEvent<Data>>.create { [weak self] observer in
            guard let self = self,
                  (self.secKey != nil) else {
                observer.on(.next(TaskUIEvent.failed(KeyChainError.unknown)))
                observer.on(.completed)
                return Disposables.create()
            }
            self.keyChainManager.decrypt(encryptedData: encryptedData, with: self.secKey!) { (decryptedData) in
                guard (decryptedData != nil) else {
                    observer.on(.next(TaskUIEvent.failed(KeyChainError.decryptionError)))
                    observer.on(.completed)
                    return
                }
                observer.on(.next(TaskUIEvent.succeeded(decryptedData!)))
                observer.on(.completed)

            }
            return Disposables.create()
        }.startWith(.waiting)
    }

}
