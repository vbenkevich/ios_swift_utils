//
//  Created on 01/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

public protocol Validatable {

    var isValid: Bool { get }

    func invalidate()
}

public extension Array where Element == Validatable {

    var isValid: Bool {
        return self.allSatisfy {
            $0.invalidate()
            return $0.isValid
        }
    }
}

extension Observable: Validatable {

    public var isValid: Bool {
        return self.validation?.result?.isValid != false
    }

    public func invalidate() {
        validation?.invalidate()
    }
}

public extension Observable {

    @discardableResult
    func affect<TCommand: Command>(_ command: TCommand) -> Observable {
        return notify(command) { cmd, res in cmd.invalidate() }
    }
}

public extension Command {

    @discardableResult
    func dependOn<Value: Equatable>(_ observable: Observable<Value>) -> Self {
        observable.affect(self)
        return self
    }
}

public class ValidationRules {

    public class ShouldNotEmpty: ValidationRule {
        public typealias Value = String

        public init(message: String? = "Empty field", nullIsValid: Bool = false) {
            self.message = message
            self.nullIsValid = nullIsValid
        }

        public var message: String?

        public var nullIsValid: Bool

        public func check(_ data: String?) -> ValidationResult {
            if let data = data {
                return ValidationResult(!data.isEmpty, message)
            } else {
                return ValidationResult(nullIsValid, message)
            }
        }
    }
}
