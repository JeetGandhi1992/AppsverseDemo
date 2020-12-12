//
//  OnBoardingViewModel.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 10/12/20.
//

import UIKit
import RxSwift
import RxCocoa

enum OnBoardingError: Error {
    case deviceIsMalicious
}

public enum OnBoardingViewModelEvents {
    case deviceMalicious(TaskUIEvent<Bool>)
    case keyGenerated(TaskUIEvent<()>)
    case userEnrollmentStatus(TaskUIEvent<Bool>)
    case userRegistrationStatus(TaskUIEvent<Void>)
    case userLoginStatus(TaskUIEvent<Void>)
    case ignore
}

extension OnBoardingViewModelEvents: Equatable {
    public static func == (lhs: OnBoardingViewModelEvents, rhs: OnBoardingViewModelEvents) -> Bool {
        switch (lhs, rhs) {
            case (.deviceMalicious(let maliciousL), .deviceMalicious(let maliciousR)):
                return maliciousL == maliciousR
            case (.keyGenerated(let generatedL), .keyGenerated(let generatedR)):
                return generatedL == generatedR
            case (.userEnrollmentStatus(let enrolledL), .userEnrollmentStatus(let enrolledR)):
                return enrolledL == enrolledR
            case (.userRegistrationStatus(let registrationL), .userRegistrationStatus(let registrationR)):
                return registrationL == registrationR
            case (.userLoginStatus(let loginL), .userLoginStatus(let loginR)):
                return loginL == loginR
            case (.ignore, .ignore):
                return true
            default:
                return false
        }
    }
}

extension OnBoardingViewModelEvents: MapsToTaskEvent {
    public func toNetworkEvent() -> TaskUIEvent<()>? {
        switch self {
            case .deviceMalicious(let event):
                return event.ignoreResponse()
            case .keyGenerated(let event):
                return event.ignoreResponse()
            case .userEnrollmentStatus(let event):
                return event.ignoreResponse()
            case .userRegistrationStatus(let event):
                return event.ignoreResponse()
            case .userLoginStatus(let event):
                return event.ignoreResponse()
            case .ignore:
                return nil
        }
    }
}

protocol OnBoardingViewModelType: TaskViewModel {
    var keyChainHelper: KeyChainHelperType { get  }
    var events: PublishSubject<OnBoardingViewModelEvents> { get }
    var deviceSanctityManager: DeviceSanctityType { get }
}
class OnBoardingViewModel: OnBoardingViewModelType {

    var deviceSanctityManager: DeviceSanctityType
    var keyChainHelper: KeyChainHelperType
    var events: PublishSubject<OnBoardingViewModelEvents> = PublishSubject<OnBoardingViewModelEvents>()
    var isUserEnrolled = BehaviorRelay<Bool>(value: false)

    var pinEntered = BehaviorRelay<String>(value: "")
    var reEnteredPin = BehaviorRelay<String>(value: "")
    var errorMessage = BehaviorRelay<String>(value: "")

    var pinValidationStatus = BehaviorRelay<Bool>(value: false)
    var rePinValidationStatus = BehaviorRelay<Bool>(value: false)

    var disposeBag = DisposeBag()

    init(deviceSanctityManager: DeviceSanctityType, keyChainHelper: KeyChainHelperType) {
        self.deviceSanctityManager = deviceSanctityManager
        self.keyChainHelper = keyChainHelper
        setupOnBoardingEvents()
        setupValidation()
    }

    func checkDeviceSanctity() {

        if self.deviceSanctityManager.isMaliciousDevice() {
            self.events.onNext(.deviceMalicious(.failed(OnBoardingError.deviceIsMalicious)))
        } else {
            self.keyChainHelper
                .setupSecKey()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] (event) in
                    self?.events.onNext(.keyGenerated(event))
                })
                .disposed(by: disposeBag)
        }
    }

    private func setupOnBoardingEvents() {
        self.events
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (event) in
                switch event {
                    case .keyGenerated(.succeeded(_)):
                        self?.setupUserEnrolledStatus()
                    case .userEnrollmentStatus(.succeeded(let status)):
                        self?.isUserEnrolled.accept(status)
                    default:
                        break
                }
            })
            .disposed(by: disposeBag)
    }

    private func setupUserEnrolledStatus() {
        self.keyChainHelper.isUserEnrolled()
            .subscribe(onNext: { [weak self] (event) in
                self?.events.onNext(.userEnrollmentStatus(event))
            })
            .disposed(by: disposeBag)
    }

    func setupValidation() {
        self.pinEntered
            .map { $0.matches(for: Constants.pinRegex) }
            .bind(to: pinValidationStatus)
            .disposed(by: disposeBag)

        self.reEnteredPin
            .map { [weak self] reEnteredPin in
                return self?.pinEntered.value == reEnteredPin
            }
            .bind(to: rePinValidationStatus)
            .disposed(by: disposeBag)
    }

    func setupSignupAction() {
        if self.isUserEnrolled.value {
            if self.pinValidationStatus.value {
                self.keyChainHelper.verify(pin: self.pinEntered.value)
                    .subscribe(onNext: { [weak self] (event) in
                        self?.events.onNext(.userRegistrationStatus(event))
                    }).disposed(by: disposeBag)
                self.errorMessage.accept("")
            } else {
                self.errorMessage.accept("Invalid pin for Login")
            }
        } else {
            if self.pinValidationStatus.value && self.rePinValidationStatus.value {
                self.keyChainHelper.save(pin: self.pinEntered.value)
                    .subscribe(onNext: { [weak self] (event) in
                        self?.events.onNext(.userRegistrationStatus(event))
                    }).disposed(by: disposeBag)
                self.errorMessage.accept("")
            } else {
                self.errorMessage.accept("Invalid pin for SignUp")
            }
        }
    }

}
