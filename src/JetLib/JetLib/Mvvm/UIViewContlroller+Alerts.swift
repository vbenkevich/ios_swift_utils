//
//  Created on 27/12/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation
import UIKit

extension UIViewController: AlertPresenter {

    /** displays an UIAlertViewController
     title, message an cancel are optional
     ok button style: default
     when the alert is closed the returned task will be completed:
     - success if ok is tapped
     - cancelled if cancle is tapped
     */
    @discardableResult
    public func showAlert(title: String?, message: String?, ok: String, cancel: String?) -> Task<Void> {
        return showAlertImpl(title: title, message: message, ok: ok, okStyle: .default, cancel: cancel)
    }

    /** displays an UIAlertViewController
     title, message an cancel are optional
     delete button style: destructive
     when the alert is closed the returned task will be completed:
     - success if ok is tapped
     - cancelled if cancle is tapped
     */
    @discardableResult
    public func showAlert(title: String?, message: String?, delete: String, cancel: String?) -> Task<Void> {
        return showAlertImpl(title: title, message: message, ok: delete, okStyle: .destructive, cancel: cancel)
    }

    @discardableResult
    private func showAlertImpl(title: String?, message: String?, ok: String, okStyle: UIAlertAction.Style, cancel: String?) -> Task<Void> {
        let source = Task<Void>.Source()
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: ok, style: okStyle, handler: { _ in try? source.complete() }))

        if let cancel = cancel {
            alert.addAction(UIAlertAction(title: cancel, style: .cancel, handler: { _ in try? source.cancel() }))
        }

        self.present(alert, animated: true, completion: nil)

        return source.task
    }
}
