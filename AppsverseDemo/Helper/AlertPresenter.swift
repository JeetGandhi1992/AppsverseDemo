//
//  AlertPresenter.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 11/12/20.
//

import UIKit
import RxSwift

public protocol AlertPresenterType {
    func presentAlertViewController(alert: Error,
                                    presentingVC: UIViewController)
}

public class AlertPresenter: AlertPresenterType {

    private let router = Router()
    private let disposeBag = DisposeBag()

    public init() {
    }

    public func presentAlertViewController(alert: Error,
                                           presentingVC: UIViewController) {

        let alertViewController = UIAlertController(title: "Error",
                                                    message: alert.localizedDescription,
                                                    preferredStyle: .alert)

        alertViewController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))


        presentingVC.tabBarController?.tabBar.isUserInteractionEnabled = false

        presentingVC.present(alertViewController, animated: true, completion: nil)
    }

}
