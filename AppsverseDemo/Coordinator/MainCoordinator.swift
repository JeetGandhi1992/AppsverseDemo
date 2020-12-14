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
    var keyChainHelper: KeyChainHelper

    init() {
        RealmDB.setUpRealmDB()
        self.keyChainHelper = KeyChainHelper(encryptionKeyName: Constants.encryptionKeyName,
                                             passwordKeyName: Constants.passwordKeyName,
                                             keyChainManager: KeyChainManager())
        self.mainRootController = MainCoordinator.getMainMenuViewController(keyChainHelper: keyChainHelper)
    }

    private static func getMainMenuViewController(keyChainHelper: KeyChainHelper) -> UIViewController {
        let viewModel = OnBoardingViewModel(deviceSanctityManager: DeviceSanctityManager(),
                                            keyChainHelper: keyChainHelper)
        guard let viewController = Router().viewController(forViewModel: viewModel) as? OnBoardingViewController else {
            fatalError("OnBoardingViewController not found")
        }
        viewModel.events
            .asDriver(onErrorJustReturn: .ignore)
            .drive(onNext: { [weak viewController, weak keyChainHelper] (event) in
                guard let keyChainHelper = keyChainHelper else { return }
                switch event {
                    case .userRegistrationStatus(.succeeded(_)):
                        viewController?.navigationController?.pushViewController(getMainAlbumViewController(keyChainHelper: keyChainHelper),
                                                                                 animated: true)

                    case .userLoginStatus(.succeeded(_)):
                        viewController?.navigationController?.pushViewController(getMainAlbumViewController(keyChainHelper: keyChainHelper),
                                                                                 animated: true)
                    default:
                        break
                }


            })
            .disposed(by: viewModel.disposeBag)
        return viewController
    }


    private static func getMainAlbumViewController(keyChainHelper: KeyChainHelper) -> UIViewController {
        let viewModel = MainAlbumViewModel(deviceSanctityManager: DeviceSanctityManager(),
                                           keyChainHelper: keyChainHelper)

        guard let viewController = Router().viewController(forViewModel: viewModel) as? MainAlbumViewController else {
            fatalError("MainAlbumViewController not found")
        }

        viewModel.selectedAlbum
            .asDriver(onErrorJustReturn: Album())
            .drive(onNext: { [weak viewController, weak keyChainHelper] (album) in

                guard let keyChainHelper = keyChainHelper else { return }
                let albumDetailViewModel = AlbumDetailViewModel(keyChainHelper: keyChainHelper,
                                                     imagerPickerManager: ImagerPickerManager(),
                                                     album: album)

                guard let albumDetailViewController = Router().viewController(forViewModel:  albumDetailViewModel) as? AlbumDetailViewController else {
                    fatalError("AlbumDetailViewController not found")
                }
                
                viewController?.navigationController?.pushViewController(albumDetailViewController,
                                                                         animated: true)
            })
            .disposed(by: viewController.disposeBag)
        return viewController
    }

}
