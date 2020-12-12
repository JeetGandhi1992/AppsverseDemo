//
//  MainCoordinator.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 13/12/20.
//

import UIKit
import RxSwift
import RxCocoa

class MainCoordinator {

    public static let shared = MainCoordinator()
    let disposeBag = DisposeBag()

    var mainRootController: UIViewController!

    init() {
        self.mainRootController = MainCoordinator.getMainMenuViewController()
    }

    private static func getMainMenuViewController() -> UIViewController {
        let viewModel = OnBoardingViewModel(deviceSanctityManager: DeviceSanctityManager(),
                                            keyChainHelper: KeyChainHelper(encryptionKeyName: Constants.encryptionKeyName
                                                                           ,
                                                                           passwordKeyName: Constants.passwordKeyName,
                                                                           keyChainManager: KeyChainManager()))
        guard let viewController = Router().viewController(forViewModel: viewModel) as? OnBoardingViewController else {
            fatalError("OnBoardingViewController not found")
        }
        viewModel.events
            .asDriver(onErrorJustReturn: .ignore)
            .drive(onNext: { [weak viewController] (event) in
                switch event {
                    case .userRegistrationStatus(.succeeded(_)):
                        break
                    default:
                        break
                }


            })
            .disposed(by: viewModel.disposeBag)
        return viewController
    }



}
