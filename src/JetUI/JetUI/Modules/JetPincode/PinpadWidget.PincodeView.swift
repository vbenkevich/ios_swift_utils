//
//  Created by Vladimir Benkevich on 08/01/2019.
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import UIKit

extension PinpadWidget {

    class PincodeView: UIStackView {

        convenience init(configuration: PinpadWidgetConfiguration) {
            self.init(arrangedSubviews: [])
            self.configuration = configuration
            self.axis = .horizontal
            self.distribution = .fillEqually
        }

        var configuration: PinpadWidgetConfiguration!

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

        var pincode: String = "" {
            didSet {
                for index in 0..<emptyViews.count {
                    emptyViews[index].isHidden = index < pincode.count
                    filledViews[index].isHidden = index >= pincode.count
                }
            }
        }

        func setup(symbolsCount: Int) {
            spacing = configuration.horizontalSpacing
            filledViews = (0..<symbolsCount).map { _ in configuration.createFilledDot() }
            emptyViews = (0..<symbolsCount).map { _ in configuration.createEmptyDot() }
        }
    }
}
