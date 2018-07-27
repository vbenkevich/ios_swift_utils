//
//  Command.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
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
