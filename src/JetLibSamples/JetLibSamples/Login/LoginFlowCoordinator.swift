//
//  Created on 05/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetUI
import JetLib
import JetPincode

class LoginFlowCoordinator {

    static var shared: LoginFlowCoordinator!

    private let pincode: JetPincode

    weak var root: UIViewController!
    weak var currentController: UIViewController!

    lazy var storyboard = UIStoryboard(name: "Main", bundle: nil)

    init(root: UIViewController, pincode: JetPincode) {
        self.root = root
        self.currentController = root
        self.pincode = pincode
    }

    func logout() {
        root.navigationController?.popToRootViewController(animated: false)
        root.dismiss(animated: true)
    }

    func loginSuccessed() {
        var nextViewTask = Task()

        if pincode.configuration.pincodeStatus == nil {
            nextViewTask = currentController!
                .showAlert(title: "Picode", message: "Do you want to use Pincode", ok: "Yes", cancel: "No")
                .chainOnSuccess { self.setNewPincode() }
        }

        nextViewTask.notify(queue: DispatchQueue.main) { _ in
            self.showMainScreen()
        }
    }

    func showMainScreen() {
        currentController!.present(storyboard.instantiateViewController(withIdentifier: "slideMenuWithNav"), animated: true)
    }

    /// It should be different screen with inputs
    func setNewPincode() -> Task<Void> {
        try! pincode.setPincode(code: "1234")
        pincode.configuration.pincodeStatus = .use
        return currentController!.showAlert(title: "NEW PINCODE = 1234")
    }
}
