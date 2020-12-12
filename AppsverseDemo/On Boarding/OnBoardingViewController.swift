//
//  OnBoardingViewController.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 10/12/20.
//

import UIKit
import RxSwift
import RxCocoa

class OnBoardingViewController: UIViewController, TaskViewController {

    var alertPresenter: AlertPresenterType = AlertPresenter()
    var loadingSpinner: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
    var viewModel: OnBoardingViewModel! = OnBoardingViewModel(deviceSanctityManager: DeviceSanctityManager(),
                                                              keyChainHelper: KeyChainHelper(encryptionKeyName: "mainKey",
                                                                                             passwordKeyName: "passKey",
                                                                                             keyChainManager: KeyChainManager()))

    var disposeBag: DisposeBag = DisposeBag()

    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var pinTextField: UITextField!
    @IBOutlet weak var rePinTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoadingSpinner()
        setupNetworkingEventsUI()
        setupSignUpButton()
        setupTextField()
        self.viewModel.checkDeviceSanctity()
    }

    func setupSignUpButton() {
        self.viewModel.isUserEnrolled
            .asDriver()
            .drive(onNext: { [unowned self] (isEnrolled) in
                let title = isEnrolled ? "LogIn" : "SignUp"
                self.signUpButton.setTitle(title, for: .normal)
                self.rePinTextField.isHidden = isEnrolled
            })
            .disposed(by: disposeBag)

        self.signUpButton.rx
            .controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [unowned self] _ in
                self.viewModel.setupSignupAction()
            })
            .disposed(by: disposeBag)
    }

    func setupTextField() {
        self.pinTextField.rx.text
            .orEmpty
            .asObservable()
            .bind(to: self.viewModel.pinEntered)
            .disposed(by: disposeBag)

        self.rePinTextField.rx.text
            .orEmpty
            .asObservable()
            .bind(to: self.viewModel.reEnteredPin)
            .disposed(by: disposeBag)

        self.viewModel
            .errorMessage
            .bind(to: self.errorLabel.rx.text)
            .disposed(by: disposeBag)
    }

}
