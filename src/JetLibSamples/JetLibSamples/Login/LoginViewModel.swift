//
//  Created on 05/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib
import JetUI

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        login.value = nil
        password.value = nil
    }

    override func willLoadData(loader: ViewModel.DataLoader) {
        try! loader.append(service.silentLogin()).onSuccess { [coordinator] in
            coordinator.loginSuccessed()
        }
    }

    private func onExecuteLogin() -> Task<Void> {
        //workaround: because nil is valid (to hide errors at the begining) we should replace nil to empty
        if login.value == nil {
            login.value = ""
        }

        if password.value == nil {
            password.value = ""
        }

        guard [login, password].isValid else {
            return alertPresenter.showAlert(error: Exception("<TODO> invalid fields"))
        }

        return submit(task: service.login(login: login.value!, password: password.value!))
            .displayError(alertPresenter)
            .onSuccess { [coordinator] in coordinator.loginSuccessed() }
    }

    private func canExecuteLogin() -> Bool {
        return [login, password].isValid
    }
}
