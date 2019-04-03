//
//  Created on 01/12/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

open class Exception: Error, CustomStringConvertible, CustomDebugStringConvertible {

    public init(_ message: String? = nil, _ error: Error? = nil) {
        self.message = message
        self.source = error
    }

    public let message: String?

    public let source: Error?

    open var handled: Bool = false

    open var description: String {
        return message
            ?? (source as CustomStringConvertible?)?.description
            ?? source?.localizedDescription
            ?? String(describing: type(of: self))

    }

    open var debugDescription: String {
        return "\(String(describing: type(of: self))) (message: \(message ?? "nil"), source: \(String(describing: source)))"
    }
}
