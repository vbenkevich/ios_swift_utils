//
//  Created on 05/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

public protocol PincodeUIPresenterDelegate: class {

    func validate(code: String) -> Bool
}

class PincodeUIPresenter: CodeProvider {

    private let pincodeStorage: PincodeStorage
    private let viewFactory: PinpadViewFactory
    private let configuration: Configuration

    init(pincodeStorage: PincodeStorage, viewFactory: PinpadViewFactory, configuration: Configuration) {
        self.pincodeStorage = pincodeStorage
        self.viewFactory = viewFactory
        self.configuration = configuration
    }

    var currentPresentation: Presentation?

    func getCode() -> Task<String> {
        if let presentation = currentPresentation {
            return presentation.task
        }

        let config = JetPincode.shared.configuration
        let presentation = Presentation(validator: pincodeStorage, maxAttempts: config.pincodeAttempts)

        self.currentPresentation = presentation

        let biomentric = getBiometric(status: config.deviceOwnerStatus)
        let viewModel = PincodeViewModel(config: configuration, biomentricAuth: biomentric)

        viewModel.delegate = presentation

        DispatchQueue.main.async { [viewFactory] in
            presentation.controller = viewFactory.createController(viewModel)
            presentation.present()
        }

        return presentation.task.notify(queue: DispatchQueue.global()) { [self] (_) in
            if self.currentPresentation === presentation {
                self.currentPresentation = nil
            }
        }
    }

    func getBiometric(status: Configuration.DeviceOwnerAuthStatus?) -> BiometricAuth? {
        if status == Configuration.DeviceOwnerAuthStatus.use {
            return BiometricAuth(storage: pincodeStorage.storage)
        } else {
            return nil
        }
    }

    class Presentation: PincodeUIPresenterDelegate {

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
                controller.dismiss(animated: true) { [source] in
                    try! source.error(CodeProtectedStorage.InvalidCodeException(Strings.invalidPincode))
                }
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
