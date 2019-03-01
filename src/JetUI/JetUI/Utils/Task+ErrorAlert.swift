//
//  Created on 01/03/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation
import JetLib

public extension Task {

    func displayError(_ presenter: ErrorPresenter) -> Task {
        self.onFail { presenter.showError(message: ($0 as CustomStringConvertible).description) }
        return self
    }

    func displayError(_ presenter: AlertPresenter) -> Task {
        return self.chainOnFail { error in
            presenter.showAlert(error: error).map { _ in throw error }
        }
    }
}
