//
//  UIButton+Command.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation
import UIKit

extension UIButton: CommandDelegate {

    public var command: Command? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.command) as? Command }
        set {
            if self.command != nil {
                self.removeTarget(self, action: #selector(handleTouchUpInside), for: .touchUpInside)
            }

            objc_setAssociatedObject(self, &AssociatedKeys.command, newValue, .OBJC_ASSOCIATION_RETAIN)

            if newValue != nil {
                stateChanged(newValue!)
                self.addTarget(self, action: #selector(handleTouchUpInside), for: .touchUpInside)
            }
        }
    }

    public var commanParameter: Any? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.commandParameter) }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.commandParameter, newValue, .OBJC_ASSOCIATION_RETAIN)

            if let command = self.command {
                stateChanged(command)
            }
        }
    }

    public func stateChanged(_ command: Command) {
        isEnabled = command.canExecute(parameter: commanParameter)
    }

    @objc
    private func handleTouchUpInside(_ sender: UIButton) {
        command?.execute(parameter: commanParameter)
    }

    private struct AssociatedKeys {
        static var command = UInt(0)
        static var commandParameter = UInt(0)
    }
}
