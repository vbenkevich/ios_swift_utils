////
////  Created on 28/02/2019
////  Copyright © Vladimir Benkevich 2019
////
//
//import Foundation
//import JetLib
//
//extension PinpadFlow {
//
//    class StorageLocker: PinpadWidgetDelegate {
//
//        private let maxAttemps: Int
//        private weak var pinpadController: UIViewController?
//        private let source = Task<Void>.Source()
//        private let viewFactory: PinpadFlowViewControllerFactory
//
//        init(maxAttemps: Int, viewFactory: PinpadFlowViewControllerFactory) {
//            self.maxAttemps = maxAttemps
//            self.viewFactory = viewFactory
//        }
//
//        var inProgress: Bool {
//            return !task.status.isCompleted
//        }
//
//        private var isBeingDisplayed: Bool = false
//
//        private var task: Task<Void> {
//            return source.task
//        }
//
//        func unlock() -> Task<Void> {
//            if !isBeingDisplayed {
//                isBeingDisplayed = true
//                DispatchQueue.main.async {
//                    self.presentUI()
//                }
//            }
//
//            return task
//        }
//
//        func loginSuccess() {
//            pinpadController?.dismiss(animated: true) { [weak source] in
//                try? source?.complete()
//            }
//        }
//
//        func loginFailed(_ error: Error, attempt: Int) {
//            guard attempt >= maxAttemps else { return }
//
//            pinpadController?.dismiss(animated: true) { [weak source] in
//                try? source?.error(error)
//            }
//        }
//
//        func presentUI() {
//            let controller = viewFactory.create()
//            controller.widget.delegate = self
//            pinpadController = controller
//            tryPresent(controller: controller)
//        }
//
//        func tryPresent(controller: UIViewController) {
//            var presenter = UIApplication.shared.keyWindow?.rootViewController
//
//            while presenter?.presentedViewController != nil {
//                presenter = presenter?.presentedViewController
//            }
//
//            if presenter is UIAlertController || presenter == nil {
//                self.tryPresent(controller: controller)
//            } else {
//                presenter?.present(controller, animated: true)
//            }
//        }
//    }
//}
