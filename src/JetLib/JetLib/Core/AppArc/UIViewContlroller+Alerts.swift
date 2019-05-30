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
        let source = Task<Void>.Source()
        showAlertImpl(title: title, message: message, ok: ok, okStyle: .default, cancel: cancel,
                      handleOk: { try? source.complete() },
                      handleCancel: { try? source.cancel() })
        return source.task
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
        let source = Task<Void>.Source()
        showAlertImpl(title: title, message: message, ok: delete, okStyle: .destructive, cancel: cancel,
                             handleOk: { try? source.complete() },
                             handleCancel: { try? source.cancel() })
        return source.task
    }

    /// Creates UIAlertViewController and present it
    @objc
    public func showAlertImpl(title: String?,
                              message: String?,
                              ok: String,
                              okStyle: UIAlertAction.Style,
                              cancel: String?,
                              handleOk: @escaping () -> Void,
                              handleCancel: @escaping () -> Void)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: ok, style: okStyle, handler: { _ in handleOk() }))

        if let cancel = cancel {
            alert.addAction(UIAlertAction(title: cancel, style: .cancel, handler: { _ in handleCancel() }))
        }

        self.present(alert, animated: true, completion: nil)
    }
}
