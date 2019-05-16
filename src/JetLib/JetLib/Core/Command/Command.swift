//
//  Created on 27/07/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol Command: class {

    var executing: Bool { get }

    func execute(parameter: Any?)

    func canExecute(parameter: Any?) -> Bool

    func invalidate()

    func addDelegate(_ commandDelegate: CommandDelegate)

    func removeDelegate(_ commandDelegate: CommandDelegate)
}

public protocol CommandDelegate: AnyObject {

    func stateChanged(_ command: Command)
}

public extension Command {

    func execute() {
        execute(parameter: nil)
    }

    func canExecute() -> Bool {
        return canExecute(parameter: nil)
    }
}
