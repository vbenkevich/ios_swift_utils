//
//  Created on 04/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib
import LocalAuthentication

open class PincodeModule {

    public static var shared: PincodeModule = PincodeModule(configuration: PincodeConfiguration(),
                                                            viewFactory: PinpadWidget.DefaultFactory())

    public init(configuration: PincodeConfiguration, viewFactory: PinpadViewControllerFactory) {
        let keyChainStorage = KeyChainStorage(serviceName: "JetUI.PincodeModule")
        pincodeStorage = PincodeStorage(storage: keyChainStorage)

        let uiCodeProvider = UIPincodeProvider(pincodeStorage: pincodeStorage, viewFactory: viewFactory)

        self.configuration = configuration
        self.dataStorage = CodeProtectedStorage(origin: keyChainStorage.async(),
                                                validator: pincodeStorage,
                                                codeProvider: uiCodeProvider,
                                                lifetime: configuration.pincodeLifetime)
    }

    private let pincodeStorage: PincodeStorage

    public let dataStorage: AsyncDataStorage

    public let configuration: PincodeConfiguration

    public func setPincode(code: String) throws {
        try pincodeStorage.setPincode(code: code)
    }

    public func deletePincode() throws {
        try pincodeStorage.deletePincode()
    }
}

open class PincodeConfiguration {

    public var symbolsCount: Int = 4

    public var pincodeAttempts: Int = 5

    public let pincodeLifetime: TimeInterval = TimeInterval(60 * 60)

    public var pincodeStatus: PincodeStatus? {
        get { return UserDefaults.standard.value(forKey: UserDefaults.Key.pincodeStatusKey) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.pincodeStatusKey) }
    }

    public var deviceOwnerStatus: DeviceOwnerAuthStatus? {
        get { return UserDefaults.standard.value(forKey: UserDefaults.Key.deviceOwnerStatusKey) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.deviceOwnerStatusKey) }
    }

    public enum PincodeStatus: String, Codable {
        case dontUse
        case use
    }

    public enum DeviceOwnerAuthStatus: String, Codable {
        case dontUse
        case use
    }

    public class Strings {
        public static var touchIdReason: String = "unlock app"
        public static var notRecognized: String = "not recognized"
    }
}

extension UserDefaults.Key {

    static let pincodeKey = UserDefaults.Key("pincodeDataKey")

    static let pincodeStatusKey = UserDefaults.Key("pincodeStatusKey")

    static let deviceOwnerStatusKey = UserDefaults.Key("deviceOwnerStatusKey")
}

public protocol CodeValidator {

    func validate(code: String) -> Bool
}

public protocol CodeProvider {

    func getCode() -> Task<String>
}

public class CodeProtectedStorage: AsyncDataStorage {

    private let dataStorage: AsyncDataStorage
    private let codeLocker: CodeLocker
    private let codeProvider: CodeProvider

    public init(origin: AsyncDataStorage, validator: CodeValidator, codeProvider: CodeProvider, lifetime: TimeInterval) {
        self.codeProvider = codeProvider
        self.codeLocker = CodeLocker(validator: validator, lifetime: lifetime)
        self.dataStorage = origin
    }

    public func value<T: Codable>(forKey defaultName: UserDefaults.Key) -> Task<T> {
        return codeLocker.tryUnlock(codeProvider: codeProvider).chainOnSuccess { [dataStorage] in
            dataStorage.value(forKey: defaultName)
        }
    }

    public func set<T: Codable>(_ value: T, forKey defaultName: UserDefaults.Key) -> Task<Void> {
        return codeLocker.tryUnlock(codeProvider: codeProvider).chainOnSuccess { [dataStorage] in
            dataStorage.set(value, forKey: defaultName)
        }
    }

    public func invalidate() {
        codeLocker.invalidate()
    }

    public class InvalidCodeException: Exception {
    }

    class CodeLocker {

        let validator: CodeValidator
        let lifetime: TimeInterval

        var lastUnlockTime: Date = Date()
        var unlockTask: Task<Void>?

        init(validator: CodeValidator, lifetime: TimeInterval) {
            self.validator = validator
            self.lifetime = lifetime
        }

        public func tryUnlock(codeProvider: CodeProvider) -> Task<Void> {
            if (lastUnlockTime + lifetime) < Date() {
                unlockTask = nil
            }

            if let task = unlockTask {
                return task
            }

            let task = codeProvider.getCode().map { [validator] in
                guard validator.validate(code: $0) else {
                    throw InvalidCodeException()
                }
            }

            unlockTask = task

            return task
        }

        public func invalidate() {
            unlockTask = nil
        }
    }
}

public class PincodeStorage: CodeValidator {

    let storage: KeyChainStorage

    public init(storage: KeyChainStorage) {
        self.storage = storage
    }

    public func validate(code: String) -> Bool {
        do {
            let stored: String = try storage.value(forKey: UserDefaults.Key.pincodeKey)
            return code == stored
        } catch {
            return false
        }
    }

    public func setPincode(code: String) throws {
        try storage.set(code, forKey: UserDefaults.Key.pincodeKey)
    }

    public func deletePincode() throws {
        try storage.delete(key: UserDefaults.Key.pincodeKey)
    }
}

public class DevideOwnerLock {

    public enum AuthType {
        case faceID
        case touchID
        case unknown
        case none
    }

    private let storage: KeyChainStorage
    private let context = LAContext()

    public init(storage: KeyChainStorage) {
        self.storage = storage
    }

    public var type: AuthType {
        if #available(iOS 11.0, *) {
            switch context.biometryType {
                case .LABiometryNone:   return .none
                case .faceID:           return .faceID
                case .touchID:          return .touchID
                default:                return .unknown
            }
        } else {
            var error: NSError?
            return context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) ? .touchID : .none
        }
    }

    public func getCode() -> Task<String> {
        return checkDeviceOwnerAuth().map { [storage] in
            return try storage.value(forKey: UserDefaults.Key.pincodeKey)
        }
    }

    public func checkDeviceOwnerAuth() -> Task<Void> {
        let taskSource = Task<Void>.Source()

        context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: PincodeConfiguration.Strings.touchIdReason)
        {
            if let error = $1 {
                try? taskSource.error(Exception(nil, error))
            } else if $0 {
                try? taskSource.complete()
            } else {
                try? taskSource.error(Exception(PincodeConfiguration.Strings.notRecognized))
            }
        }

        return taskSource.task
    }
}

public protocol UIPincodeProviderDelegate: class {

    func validate(code: String) -> Bool
}

class UIPincodeProvider: CodeProvider {

    private let pincodeStorage: PincodeStorage
    private let viewFactory: PinpadViewControllerFactory

    init(pincodeStorage: PincodeStorage, viewFactory: PinpadViewControllerFactory) {
        self.pincodeStorage = pincodeStorage
        self.viewFactory = viewFactory
    }

    var currentPresentation: Presentation?

    func getCode() -> Task<String> {
        if let presentation = currentPresentation {
            return presentation.task
        }

        let config = PincodeModule.shared.configuration
        let presentation = Presentation(validator: pincodeStorage, maxAttempts: config.pincodeAttempts)

        self.currentPresentation = presentation

        let deviceOwnerLock = getDeviceOwnerLock(status: config.deviceOwnerStatus)

        DispatchQueue.main.async { [viewFactory] in
            let viewModel = PinpadWidget.PinpadViewModel(symbolsCount: config.symbolsCount,
                                                         deviceOwnerLock: deviceOwnerLock)
            presentation.controller = viewFactory.create(viewModel: viewModel)
            presentation.present()
        }

        return presentation.task.notify(queue: DispatchQueue.global()) { [self] (_) in
            if self.currentPresentation === presentation {
                self.currentPresentation = nil
            }
        }
    }

    func getDeviceOwnerLock(status: PincodeConfiguration.DeviceOwnerAuthStatus?) -> DevideOwnerLock? {
        if status == PincodeConfiguration.DeviceOwnerAuthStatus.use {
            return DevideOwnerLock(storage: pincodeStorage.storage)
        } else {
            return nil
        }
    }

    class Presentation {

        private let validator: CodeValidator
        private let maxAttempts: Int
        private let source = Task<String>.Source()

        init(validator: CodeValidator, maxAttempts: Int) {
            self.maxAttempts = maxAttempts
            self.validator = validator
        }

        var task: Task<String> {
            return source.task
        }

        var controller: UIViewController!

        private var attempt = 0
        private var isPresented: Bool = false

        func present() {
            if isPresented {
                return
            }

            isPresented = true
            tryPresent(controller: controller)
        }

        func validate(code: String) -> Bool {
            attempt += 1

            if validator.validate(code: code) {
                controller.dismiss(animated: true) { [source] in try! source.complete(code) }
                return true
            }

            if attempt == maxAttempts {
                controller.dismiss(animated: true) { [source] in try! source.error(CodeProtectedStorage.InvalidCodeException()) }
            }

            return false
        }

        private func tryPresent(controller: UIViewController) {
            var presenter = UIApplication.shared.keyWindow?.rootViewController

            while presenter?.presentedViewController != nil {
                presenter = presenter?.presentedViewController
            }

            if presenter is UIAlertController || presenter == nil {
                self.tryPresent(controller: controller)
            } else {
                presenter?.present(controller, animated: true)
            }
        }
    }
}
