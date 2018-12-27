//
//  Created on 27/12/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

/// Provide alert displaing feature
public protocol AlertPresenter: class {

    /** displays an UIAlertViewController
     title, message an cancel are optional
     ok button style: default
     when the alert is closed the returned task will be completed:
     - success if ok is tapped
     - cancelled if cancle is tapped
     */
    @discardableResult
    func showAlert(title: String?, message: String?, ok: String, cancel: String?) -> Task<Void>

    /** displays an UIAlertViewController
     title, message an cancel are optional
     ok button style: destructive
     when the alert is closed the returned task will be completed:
     - success if ok is tapped
     - cancelled if cancle is tapped
     */
    @discardableResult
    func showAlert(title: String?, message: String?, delete: String, cancel: String?) -> Task<Void>
}


/// Default texts for AlertPresenter
public class AlertPresenterDefaults {

    public static var instance = AlertPresenterDefaults()

    public var errorTitle: String = "Error"
    public var okButtonText: String = "Ok"
    public var cancelButtonText: String = "Cancel"
}

public extension AlertPresenter {

    /**
     title:     title
     message:   nil
     ok:        AlertPresenterDefaults.instance.okButtonText
     cance:     nil
     */
    @discardableResult
    func showAlert(title: String?) -> Task<Void> {
        return showAlert(title: title,
                         message: nil,
                         ok: AlertPresenterDefaults.instance.okButtonText,
                         cancel: nil)
    }

    /**
     title:     AlertPresenterDefaults.instance.errorTitle
     message:   "\(error)"
     ok:        AlertPresenterDefaults.instance.okButtonText
     cance:     nil
     */
    @discardableResult
    func showAlert(title: String?, message: String?) -> Task<Void> {
        return showAlert(title: title,
                         message: message,
                         ok: AlertPresenterDefaults.instance.okButtonText,
                         cancel: nil)
    }

    /**
     title:     title
     message:   message
     ok:        AlertPresenterDefaults.instance.okButtonText
     cance:     AlertPresenterDefaults.instance.cancelButtonText
     */
    @discardableResult
    func showOkCancelAlert(title: String?, message: String?) -> Task<Void> {
        return showAlert(title: title,
                         message: message,
                         ok: AlertPresenterDefaults.instance.okButtonText,
                         cancel: nil)
    }

    /**
     title:     AlertPresenterDefaults.instance.errorTitle
     message:   "\(error)"
     ok:        AlertPresenterDefaults.instance.okButtonText
     cance:     nil
     */
    @discardableResult
    func showAlert(error: Error) -> Task<Void> {
        return showAlert(title: AlertPresenterDefaults.instance.errorTitle,
                         message: "\(error)",
                         ok: AlertPresenterDefaults.instance.okButtonText,
                         cancel: nil)
    }
}
