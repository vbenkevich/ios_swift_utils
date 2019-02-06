//
//  Created on 06/02/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

open class PinpadFlow {

    public class PinpadFlowException: Exception {
        public static let keyNotFoundException: PinpadFlowException = PinpadFlowException("Key not found")
        public static let pincodeDoesntSetException: PinpadFlowException = PinpadFlowException("Pincode doesn't set")
    }

    public static var shared: PinpadFlow = PinpadFlow()

    public var maxInactivityTime: TimeInterval = TimeInterval(1 * 60 * 60) // 1 hour
    public var incorrectPinAttempts: Int = 5
    public var viewFactory: PinpadViewFactory = PinpadViewFactory()

    public static var isPincodeInited: Bool {
        get { return UserDefaults.standard.bool(forKey: UserDefaults.Key.isPincodeInited) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.isPincodeInited) }
    }

    public static var dontUsePincode: Bool {
        get { return UserDefaults.standard.bool(forKey: UserDefaults.Key.dontUsePincode) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.dontUsePincode) }
    }

    private var storage = DataStorage() //TODO use encrypted
    private var lastBackgroudTime = Date()

    private var _authentificator: Authentificator?
    private var authentificator: Authentificator {
        get {
            _authentificator = _authentificator ?? Authentificator(maxAttemps: incorrectPinAttempts, viewFactory: viewFactory)
            return _authentificator!
        }
        set {
            _authentificator = newValue
        }
    }

    open func applicationDidBecomeActive() {
        guard lastBackgroudTime.addingTimeInterval(maxInactivityTime) < Date(), !authentificator.inProgress else {
            return
        }

        authentificator = Authentificator(maxAttemps: incorrectPinAttempts, viewFactory: viewFactory)
    }

    open func applicationDidEnterBackground() {
        lastBackgroudTime = Date()
    }

    open func set<T: Codable>(_ data: T, forKey key: UserDefaults.Key) throws -> Task<Void> {
        guard PinpadFlow.isPincodeInited, !PinpadFlow.dontUsePincode else {
            throw PinpadFlowException.pincodeDoesntSetException
        }

        return authentificator.authentificate().map {
            try self.storage.set(data, forKey: key)
        }
    }

    open func data<T: Codable>(forKey key: UserDefaults.Key) throws -> Task<T> {
        guard PinpadFlow.isPincodeInited, !PinpadFlow.dontUsePincode else {
            throw PinpadFlowException.pincodeDoesntSetException
        }

        return authentificator.authentificate().map {
            try self.storage.data(forKey: key)
        }
    }

    //TODO use encrypted storage
    private class DataStorage {

        func set<T: Codable>(_ data: T, forKey key: UserDefaults.Key) throws {
            UserDefaults.standard.set(data, forKey: key)
        }

        func data<T: Codable>(forKey key: UserDefaults.Key) throws -> T {
            guard let data: T = UserDefaults.standard.value(forKey: key) else {
                throw PinpadFlowException.keyNotFoundException
            }

            return data
        }
    }
}

extension PinpadFlow {

    class Authentificator: PinpadFlowDelegate {

        private let maxAttemps: Int
        private weak var pinpadController: UIViewController?
        private let source = Task<Void>.Source()
        private let viewFactory: PinpadViewFactory

        init(maxAttemps: Int, viewFactory: PinpadViewFactory) {
            self.maxAttemps = maxAttemps
            self.viewFactory = viewFactory
        }

        var inProgress: Bool {
            return !task.status.isCompleted
        }

        private var isBeingDisplayed: Bool = false

        private var task: Task<Void> {
            return source.task
        }

        func authentificate() -> Task<Void> {
            if !isBeingDisplayed {
                isBeingDisplayed = true
                presentUI()
            }

            return task
        }

        func loginSuccess() {
            pinpadController?.dismiss(animated: true) { [weak source] in
                try? source?.complete()
            }
        }

        func loginFailed(_ error: Error, attempt: Int) {
            guard attempt >= maxAttemps else { return }

            pinpadController?.dismiss(animated: true) { [weak source] in
                try? source?.error(error)
            }
        }

        func presentUI() {
            let (controller, widget) = viewFactory.createViews()
            widget.delegate = self
            pinpadController = controller
            tryPresent(controller: controller)
        }

        func tryPresent(controller: UIViewController) {
            var presenter = UIApplication.shared.keyWindow?.rootViewController

            while presenter?.presentedViewController != nil {
                presenter = presenter?.presentedViewController
            }

            if presenter is UIAlertController || presenter == nil {
                DispatchQueue.main.execute(after: .seconds(1)) {
                    self.tryPresent(controller: controller)
                }
            } else {
                presenter?.present(controller, animated: true)
            }
        }
    }
}

extension UserDefaults.Key {
    static let isPincodeInited = UserDefaults.Key("JetUI.PinpadFlow.isPincodeInited")
    static let dontUsePincode = UserDefaults.Key("JetUI.PinpadFlow.dontUsePincode")
}
