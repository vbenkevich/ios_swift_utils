//
//  Created on 27/07/2018
//  Copyright © Vladimir Benkevich 2018
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
                newValue?.addDelegate(self)
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

    public var hideIfCantExecuteCommand: Bool {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.hideIfCantExecute) as? Bool ?? false }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.hideIfCantExecute, newValue, .OBJC_ASSOCIATION_COPY)

            if let command = self.command {
                stateChanged(command)
            }
        }
    }

    public func stateChanged(_ command: Command) {
        isEnabled = command.canExecute(parameter: commanParameter)

        if hideIfCantExecuteCommand {
            isHidden = !isEnabled
        }
    }

    @objc
    private func handleTouchUpInside(_ sender: UIButton) {
        command?.execute(parameter: commanParameter)
    }

    private struct AssociatedKeys {
        static var command = UInt(0)
        static var commandParameter = UInt(0)
        static var hideIfCantExecute = UInt(0)
    }
}
