//
//  PinpadWidget.PincodeView.swift
//  JetUI
//
//  Created by Vladimir Benkevich on 08/01/2019.
//

import Foundation
import UIKit

extension PinpadWidget {

    class PincodeView: UIStackView {

        var count: Int = 0

        var configuration: PinpadConfiguration!

        var filledViews: [UIView] = [] {
            didSet {
                for view in oldValue {
                    removeArrangedSubview(view)
                }
                for (index, view) in filledViews.enumerated() {
                    addArrangedSubview(view)
                    view.isHidden = index >= pincode.count
                }
            }
        }

        var emptyViews: [UIView] = [] {
            didSet {
                for view in oldValue {
                    removeArrangedSubview(view)
                }
                for (index, view) in emptyViews.enumerated() {
                    addArrangedSubview(view)
                    view.isHidden = index < pincode.count
                }
            }
        }

        convenience init(configuration: PinpadConfiguration) {
            self.init(arrangedSubviews: [])
            self.configuration = configuration
            self.axis = .horizontal
            self.distribution = .fillEqually
        }

        var pincode: String = "" {
            didSet {
                for index in 0..<emptyViews.count {
                    emptyViews[index].isHidden = index < pincode.count
                    filledViews[index].isHidden = index >= pincode.count
                }
            }
        }

        func setup(delegate: PinpadDelegate?) {
            guard let delegate = delegate else { return }

            spacing = configuration.horizontalSpacing
            filledViews = (0..<delegate.symbolsCount).map { _ in configuration.createFilledDot() }
            emptyViews = (0..<delegate.symbolsCount).map { _ in configuration.createEmptyDot() }
        }
    }
}
