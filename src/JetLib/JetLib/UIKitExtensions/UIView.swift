//
//  Created by Vladimir Benkevich on 07/01/2019.
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import UIKit

public extension UIView {

    func embedInView(insets: UIEdgeInsets = UIEdgeInsets.zero) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.clear
        container.addSubview(self)

        equalSizeConstraints(to: container)

        return container
    }

    @discardableResult
    func equalSizeConstraints(to view: UIView, insets: UIEdgeInsets = UIEdgeInsets.zero, activate: Bool = true) -> [NSLayoutConstraint] {
        let constraints = [
            self.leftAnchor.constraint(equalTo: view.leftAnchor, constant: insets.left),
            self.topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            self.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -insets.right),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        ]

        constraints.forEach { $0.isActive = activate }

        return constraints
    }
}

open class RoundedButton: UIButton {

    open override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(frame.width, frame.height) / 2
    }
}

open class RoundedView: UIView {

    open override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(frame.width, frame.height) / 2
    }
}
