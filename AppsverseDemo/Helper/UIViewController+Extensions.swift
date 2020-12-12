//
//  UIViewController+Extensions.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 11/12/20.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIViewController {

    public var viewDidLoad: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.viewDidLoad)).map { _ in }
        return ControlEvent(events: source)
    }

    public var viewWillAppear: ControlEvent<Bool> {
        let source = self.methodInvoked(#selector(Base.viewWillAppear)).map { $0.first as? Bool ?? false }
        return ControlEvent(events: source)
    }
    public var viewDidAppear: ControlEvent<Bool> {
        let source = self.methodInvoked(#selector(Base.viewDidAppear)).map { $0.first as? Bool ?? false }
        return ControlEvent(events: source)
    }

    public var viewWillDisappear: ControlEvent<Bool> {
        let source = self.methodInvoked(#selector(Base.viewWillDisappear)).map { $0.first as? Bool ?? false }
        return ControlEvent(events: source)
    }
    public var viewDidDisappear: ControlEvent<Bool> {
        let source = self.methodInvoked(#selector(Base.viewDidDisappear)).map { $0.first as? Bool ?? false }
        return ControlEvent(events: source)
    }

    public var viewWillLayoutSubviews: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.viewWillLayoutSubviews)).map { _ in }
        return ControlEvent(events: source)
    }
    public var viewDidLayoutSubviews: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.viewDidLayoutSubviews)).map { _ in }
        return ControlEvent(events: source)
    }

    public var willMoveToParentViewController: ControlEvent<UIViewController?> {
        let source = self.methodInvoked(#selector(Base.willMove)).map { $0.first as? UIViewController }
        return ControlEvent(events: source)
    }
    public var didMoveToParentViewController: ControlEvent<UIViewController?> {
        let source = self.methodInvoked(#selector(Base.didMove)).map { $0.first as? UIViewController }
        return ControlEvent(events: source)
    }

    public var didReceiveMemoryWarning: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.didReceiveMemoryWarning)).map { _ in }
        return ControlEvent(events: source)
    }

    /// Rx observable, triggered when the ViewController appearance state changes (true if the View is being displayed, false otherwise)
    public var isVisible: Observable<Bool> {
        let viewDidAppearObservable = self.base.rx.viewDidAppear.map { _ in true }
        let viewWillDisappearObservable = self.base.rx.viewWillDisappear.map { _ in false }
        return Observable<Bool>.merge(viewDidAppearObservable, viewWillDisappearObservable)
    }

    /// Rx observable, triggered when the ViewController is being dismissed
    public var isDismissing: ControlEvent<Bool> {
        let source = self.sentMessage(#selector(Base.dismiss)).map { $0.first as? Bool ?? false }
        return ControlEvent(events: source)
    }

}


extension UIViewController {

    public static var currentRootViewController: UIViewController {
        guard let window = UIApplication.shared.delegate?.window as? UIWindow else {
            fatalError("Window unavailable")
        }

        guard let rootViewController = window.rootViewController else {
            fatalError("root view controller not available")
        }

        guard let presentedViewController = rootViewController.presentedViewController else {
            return rootViewController
        }

        return presentedViewController
    }

    public static func make<T: ViewControllerProtocol>(viewController: T.Type, viewModel: T.ViewModelT, from storyBoard: String = "Main") -> T where T: UIViewController {
        var vc = make(viewController: viewController, from: storyBoard)
        vc.viewModel = viewModel
        return vc
    }

    public static func make<T: UIViewController>(viewController: T.Type, from storyBoard: String) -> T {
        let viewControllerName = String(describing: viewController)

        if storyBoard.isEmpty {
            let viewController = T(nibName: viewControllerName, bundle: nil) as T
            return viewController
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: viewController as AnyClass))

            guard let viewController = storyboard.instantiateViewController(withIdentifier: viewControllerName) as? T else {
                fatalError("Unable to create ViewController: \(viewControllerName) from storyboard: \(storyboard)")
            }
            return viewController
        }
    }
}

