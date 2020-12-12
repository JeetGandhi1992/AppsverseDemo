//
//  ViewControllerProtocol.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 7/12/20.
//

import UIKit
import RxSwift
import RxCocoa

public protocol ViewControllerProtocol {
    associatedtype ViewModelT
    var viewModel: ViewModelT! { get set }
}

public protocol TaskViewController: ViewControllerProtocol where Self: UIViewController, ViewModelT: TaskViewModel {
    var alertPresenter: AlertPresenterType { get }
    var disposeBag: DisposeBag { get }
    var loadingSpinner: UIActivityIndicatorView { get }

    func setupNetworkingEventsUI()
    func setupLoadingSpinner()
}

extension TaskViewController {

    public func setupLoadingSpinner() {
        let screenFrame = UIScreen.main.bounds
        let screenHeight = screenFrame.height
        let screenWidth = screenFrame.width
        let height = (screenHeight/2) - 23
        let width = (screenWidth/2) - 23
        self.loadingSpinner.frame = CGRect(x: width, y: height, width: 46, height: 46)
        self.view.addSubview(self.loadingSpinner)
    }

    public func setupNetworkingEventsUI() {
        self.viewModel.events
            .compactMap { $0.toNetworkEvent() }
            .asDriver(onErrorJustReturn: .failed(KeyChainError.unknown))
            .drive(onNext: { [weak self] event in
                DispatchQueue.main.async { [weak self] in
                    guard let _self = self else { return }
                    switch event {
                        case .waiting:
                            _self.loadingSpinner.startAnimating()
                        case .succeeded:
                            _self.loadingSpinner.stopAnimating()
                        case .failed(let error):
                            _self.loadingSpinner.stopAnimating()
                            _self.presentError(error: error)
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }

    public func setupErrorDisplayEvent() {
        self.viewModel.events
            .compactMap { $0.toNetworkEvent() }
            .subscribe(onNext: { [weak self] event in
                guard let _self = self else { return }
                switch event {
                    case .failed(let error):
                        _self.presentError(error: error)

                    default:
                        break
                }
            })
            .disposed(by: self.disposeBag)
    }

    func presentError(error: Error) {
        self.alertPresenter.presentAlertViewController(alert: error,
                                                       presentingVC: UIViewController.currentRootViewController)
    }

}
