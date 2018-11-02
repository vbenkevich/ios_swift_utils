//
//  BindingSampleController.swift
//  JetLibSamples
//
//  Created by Vladimir Benkevich on 02/11/2018.
//  Copyright © 2018 Vladimir Benkevich. All rights reserved.
//

import Foundation
import UIKit
import JetLib

class BindingControllerViewModel: ViewModel {

    var property = Observable("")
        .addThrottling(DispatchTimeInterval.milliseconds(500))
        .addValidation(mode: .onValueChanged)
        .addValidationRule(PropertyValidator())

    override func viewWillAppear(_ animated: Bool) {
        property.value = "viewWillAppear"
    }

    override func viewDidAppear(_ animated: Bool) {
        property.value = "viewDidAppear"
    }

    struct PropertyValidator: ValidationRule {
        typealias Data = String

        func check(_ data: String?) -> ValidationResult {
            guard data == nil || data == "correct" else {
                return ValidationResult("type \"correct\"")
            }

            return ValidationResult()
        }
    }
}

class BindingSampleController: UIViewController {

    var viewModel = BindingControllerViewModel()

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        try! textField.bind(to: viewModel.property).with(errorPresenter: errorLabel)
        try! titleLabel.bind(to: viewModel.property)
    }
}
