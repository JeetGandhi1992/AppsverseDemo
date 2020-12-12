//
//  Router.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 11/12/20.
//

import UIKit

protocol RouterProtocol {
    func viewController(forViewModel viewModel: Any) -> UIViewController
}

struct Router: RouterProtocol {
    func viewController(forViewModel viewModel: Any) -> UIViewController {
        switch viewModel {

            // MARK: OTHERS
            case let viewModel as OnBoardingViewModel:
                return UIViewController.make(viewController: OnBoardingViewController.self, viewModel: viewModel)


            default:
                fatalError("Unable to find corresponding View Controller for \(viewModel)")
        }
    }

}
