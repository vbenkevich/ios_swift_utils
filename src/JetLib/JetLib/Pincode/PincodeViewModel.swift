//
//  Created on 18/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

public class PincodeViewModel: ExtendedViewModel {

    public init(config: JetPincodeConfiguration, biomentricAuth: BiometricAuth?) {
        self.config = config
        self.biomentricAuth = biomentricAuth
        self.validaor = PincodeValidator(config)
    }

    fileprivate let validaor: PincodeValidator

    let config: JetPincodeConfiguration

    let biomentricAuth: BiometricAuth?

    lazy var deleteSymbolCommand = CommandFactory.owner(self)
        .action { $0.executeDeleteSymbol() }
        .predicate {$0.canExecuteDeleteSymbol() }
        .dependOn(pincode)

    lazy var appendSymbolCommand = CommandFactory.owner(self)
        .action { $0.executeAppendSymbol($1) }
        .dependOn(pincode)

    lazy var biomentricAuthCommand = CommandFactory.owner(self)
        .task { $0.executeBiomentricAuth() }
        .predicate { $0.canExecuteBiomentricAuth() }
        .dependOn(pincode)

    public weak var delegate: PincodeUIPresenterDelegate? {
        didSet {
            validaor.delegate = delegate
        }
    }

    lazy var pincode = Observable<String>("").validation(validaor)

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if config.showBiometricAuthOnDidAppear {
            biomentricAuthCommand.execute()
        }
    }

    fileprivate func executeAppendSymbol(_ symbol: String) {
        pincode.value = (pincode.value ?? "") + symbol
    }

    fileprivate func executeDeleteSymbol() {
        guard let code = pincode.value else { return }
        pincode.value = String(code.prefix(code.count - 1))
    }

    fileprivate func canExecuteDeleteSymbol() -> Bool {
        guard let code = pincode.value else { return false }
        return !code.isEmpty && code.count < config.symbolsCount
    }

    fileprivate func executeBiomentricAuth() -> Task<String> {
        guard let lock = biomentricAuth else { return Task("") }
        return self.submit(task: lock.getCode())
            .onSuccess { [delegate] in _ = delegate?.validate(code: $0) }
    }

    fileprivate func canExecuteBiomentricAuth() -> Bool {
        return biomentricAuth != nil
    }

    fileprivate class PincodeValidator: ValidationRule {
        typealias Value = String

        init(_ config: JetPincodeConfiguration) {
            self.config = config
        }

        let config: JetPincodeConfiguration

        weak var delegate: PincodeUIPresenterDelegate?

        func check(_ data: String?) -> ValidationResult {
            guard let code = data, config.symbolsCount == code.count else {
                return ValidationResult(true)
            }

            return ValidationResult(delegate?.validate(code: code) == true)
        }
    }
}
