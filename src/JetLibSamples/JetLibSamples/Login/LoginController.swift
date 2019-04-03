//
//  Created on 05/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

class LoginController: UIViewController {

    var viewModel: LoginViewModel!

    @IBOutlet weak var loginField: UITextField!
    @IBOutlet weak var loginError: UILabel!

    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordError: UILabel!

    @IBOutlet weak var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        LoginFlowCoordinator.shared = LoginFlowCoordinator(root: self, pincode: JetPincode.shared) // todo -> AppDelegate
        viewModel = LoginViewModel(service: AuthService(pincode: JetPincode.shared), coordinator: LoginFlowCoordinator.shared)

        sendViewAppearance(to: viewModel)

        viewModel.alertPresenter = self

        loginButton.command = viewModel.loginCommand

        try! loginField.bind(to: viewModel.login, mode: BindingMode.twoWayLostFocus)
            .with(errorPresenter: loginError)

        try! passwordField.bind(to: viewModel.password, mode: BindingMode.twoWayLostFocus)
            .with(errorPresenter: passwordError)
    }

    @IBAction func handleButtonClick(_ sender: Any) {
        view.endEditing(true)
    }

    @IBAction func handleBackgrounTap(_ sender: Any) {
        view.endEditing(true)
    }
}
