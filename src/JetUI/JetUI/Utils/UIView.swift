//
//  UIView.swift
//  JetUI
//
//  Created by Vladimir Benkevich on 07/01/2019.
//

import Foundation
import UIKit

extension UIView {

    func embedInView(insets: UIEdgeInsets = UIEdgeInsets.zero) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.clear
        container.insertSubview(self, at: 0)

        container.leftAnchor.constraint(equalTo: leftAnchor, constant: insets.left).isActive = true
        container.topAnchor.constraint(equalTo: topAnchor, constant: insets.top).isActive = true
        rightAnchor.constraint(equalTo: container.rightAnchor, constant: insets.right).isActive = true
        bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: insets.bottom).isActive = true

        return container
    }
}
