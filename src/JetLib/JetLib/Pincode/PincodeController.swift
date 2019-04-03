//
//  Created on 18/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import UIKit

open class PincodeController: UIViewController {

    open var backgroundView: UIView?

    open var headerView: UIView?

    var viewModel: PincodeViewModel!

    var pinpad: (UIView & Pinpad)! {
        didSet {
            pinpad.setAppendCommand(viewModel.appendSymbolCommand)
            pinpad.setDeleteCommand(viewModel.deleteSymbolCommand)
            pinpad.setBiometricCommand(viewModel.biomentricAuthCommand)
        }
    }

    open override func loadView() {
        let root = backgroundView ?? {
            let view = UIView()
            let effectView = UIVisualEffectView()
            effectView.effect = UIBlurEffect(style: .light)
            effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            effectView.frame = view.bounds
            effectView.translatesAutoresizingMaskIntoConstraints = true
            view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            view.addSubview(effectView)
            return view
        }()

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        if let header = headerView {
            stack.addArrangedSubview(header)
        }

        stack.addArrangedSubview(pinpad)

        root.addSubview(stack)

        stack.centerXAnchor.constraint(equalTo: root.centerXAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: root.centerYAnchor).isActive = true
        stack.widthAnchor.constraint(equalTo: root.widthAnchor, multiplier: 0.67).isActive = true

        if #available(iOS 11.0, *) {
            stack.topAnchor.constraint(greaterThanOrEqualTo: root.safeAreaLayoutGuide.topAnchor, constant: 24).isActive = true
            stack.leftAnchor.constraint(greaterThanOrEqualTo: root.safeAreaLayoutGuide.leftAnchor, constant: 24).isActive = true
        } else {
            stack.topAnchor.constraint(greaterThanOrEqualTo: root.topAnchor, constant: 24).isActive = true
            stack.leftAnchor.constraint(greaterThanOrEqualTo: root.leftAnchor, constant: 24).isActive = true
        }

        view = root
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.wire(with: self)

        viewModel.pincode.notify(self) {
            $0.pinpad.display(code: $1 ?? "")
        }

        viewModel.pincode.validation?.notify(self) { controller, result in
            if result?.isValid == false {
                controller.pinpad.invalideCode { controller.viewModel.pincode.value = "" }
            }
        }
    }
}
