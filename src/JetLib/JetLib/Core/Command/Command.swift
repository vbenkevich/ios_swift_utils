//
//  Created on 27/07/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol Command: class {

    var executing: Bool { get }

    var delegate: CommandDelegate? { get set }

    func execute(parameter: Any?)

    func canExecute(parameter: Any?) -> Bool

    func invalidate()
}

public protocol CommandDelegate: class {

    func stateChanged(_ command: Command)
}

public extension Command {

    func execute() {
        execute(parameter: nil)
    }
}
