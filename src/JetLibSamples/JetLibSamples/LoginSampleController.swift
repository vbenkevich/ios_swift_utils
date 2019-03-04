//
//  Created on 01/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import UIKit
import JetLib
import JetUI

class AuthService {

    private static var loginKey = UserDefaults.Key("storage.key.login")
    private static var passwordKey = UserDefaults.Key("storage.key.password")

    func login(login: String, password: String) -> Task<Void> {
        return Task().delay(1000)
    }

    func logout() {
        try! PinpadFlow.shared.delete(key: AuthService.loginKey)
        try! PinpadFlow.shared.delete(key: AuthService.passwordKey)
    }

    func silentLogin() -> Task<Void> {
        guard PinpadFlow.isPincodeInited && !PinpadFlow.dontUsePincode else {
            return Task.cancelled()
        }

        let storage = PinpadFlow.shared
        var login: String?
        var password: String?

        let getLogin = try! storage.data(forKey: AuthService.loginKey).map { login = $0 }
        let getPassword = try! storage.data(forKey: AuthService.passwordKey).map { password = $0 }

        return TaskGroup([getLogin, getPassword])
            .whenAll()
            .chainOnSuccess { self.login(login: login!, password: password!) }
    }
}

class LoginFlowCoordinator {

    func loginSuccessed() {
    }
}

class LoginViewModel: ViewModel {

    private let service: AuthService
    private let coordinator: LoginFlowCoordinator

    init(service: AuthService, coordinator: LoginFlowCoordinator) {
        self.service = service
        self.coordinator = coordinator
    }

    var login = Observable<String>()
        .validation(ValidationRules.ShouldNotEmpty(nullIsValid: true))

    var password = Observable<String>()
        .validation(ValidationRules.ShouldNotEmpty(nullIsValid: true))

    var alertPresenter: AlertPresenter!

    lazy var loginCommand = AsyncCommand(self, task: { $0.onExecuteLogin() }, canExecute: { $0.canExecuteLogin() })
        .dependOn(login)
        .dependOn(password)

    override func willLoadData(loader: ViewModel.DataLoader) {
        try! loader.append(service.silentLogin()).onSuccess { [coordinator] in
            coordinator.loginSuccessed()
        }
    }

    private func onExecuteLogin() -> Task<Void> {
        guard [login, password].isValid else {
            return alertPresenter.showAlert(error: Exception("<TODO> invalid fields"))
        }

        return submit(task: service.login(login: login.value!, password: password.value!))
            .displayError(alertPresenter)
    }

    private func canExecuteLogin() -> Bool {
        return [login, password].isValid
    }
}

class LoginController: UIViewController {

    lazy var viewModel: LoginViewModel = LoginViewModel(service: AuthService(), coordinator: LoginFlowCoordinator())

    @IBOutlet weak var loginField: UITextField!
    @IBOutlet weak var loginError: UILabel!

    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordError: UILabel!

    @IBOutlet weak var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        sendViewAppearance(to: viewModel)
        viewModel.alertPresenter = self

        loginButton.command = viewModel.loginCommand

        try! loginField.bind(to: viewModel.login, mode: BindingMode.twoWayLostFocus)
            .with(errorPresenter: loginError)

        try! passwordField.bind(to: viewModel.password, mode: BindingMode.twoWayLostFocus)
            .with(errorPresenter: passwordError)
    }
}
