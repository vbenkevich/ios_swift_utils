//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public extension Task {

    var isCompleted: Bool {
        return status.isCompleted
    }

    var isSuccess: Bool {
        return status.isSuccess
    }

    var isFailed: Bool {
        return status.isFailed
    }

    var isCancelled: Bool {
        return status.isCancelled
    }

    var error: Error? {
        switch status {
        case .failed(let err):
            return err
        default:
            return nil
        }
    }

    enum Status: Equatable {

        case new
        case executing
        case success(_: T)
        case cancelled
        case failed(_: Swift.Error)

        public var isCompleted: Bool {
            switch self {
            case .success(_), .cancelled, .failed(_):
                return true
            default:
                return false
            }
        }

        public var isSuccess: Bool {
            switch self {
            case .success(_):
                return true
            default:
                return false
            }
        }

        public var isFailed: Bool {
            switch self {
            case .failed(_):
                return true
            default:
                return false
            }
        }

        public var isCancelled: Bool {
            switch self {
            case .cancelled:
                return true
            default:
                return false
            }
        }

        public static func == (lhs: Task<T>.Status, rhs: Task<T>.Status) -> Bool {
            switch (lhs, rhs) {
            case (.new, .new):
                return true
            case (.executing, .executing):
                return true
            case (.cancelled, .cancelled):
                return true
            case (.failed(_), .failed(_)):
                return true
            case (.success(_), .success(_)):
                return true
            default:
                return false
            }
        }
    }
}
