//
//  TaskViewModel.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 10/12/20.
//

import Foundation
import RxSwift

public protocol TaskViewModel {
    associatedtype EventType: MapsToTaskEvent

    var events: PublishSubject<EventType> { get }
}

public protocol MapsToTaskEvent {
    func toNetworkEvent() -> TaskUIEvent<()>?
}

public enum TaskUIEvent<ResponseType> {
    case waiting
    case succeeded(ResponseType)
    case failed(Error)

    public func ignoreResponse() -> TaskUIEvent<()> {
        switch self {
            case .succeeded:
                return .succeeded(())
            case .failed(let error):
                return .failed(error)
            case .waiting:
                return .waiting
        }
    }
}

extension TaskUIEvent: Equatable {

    public static func == (lhs: TaskUIEvent, rhs: TaskUIEvent) -> Bool {
        switch (lhs, rhs) {
            case (.waiting, .waiting):
                return true
            case (.succeeded, .succeeded):
                return true
            case (.failed(let errorA), .failed(let errorB)):
                return errorA.localizedDescription == errorB.localizedDescription
            default:
                return false
        }
    }
}
