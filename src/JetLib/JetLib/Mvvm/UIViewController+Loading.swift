//
//  Created on 27/12/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation
import UIKit

private var loadingPresenterKey: Int32 = 0

extension UIViewController {

    fileprivate var currentLoadingPresenter: LoadingPresenter? {
        get { return objc_getAssociatedObject(self, &loadingPresenterKey) as? LoadingPresenter }
        set { objc_setAssociatedObject(self, &loadingPresenterKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }

    public func getLoadingPresenter() -> LoadingPresenter? {
        if currentLoadingPresenter == nil {
            currentLoadingPresenter = createAndAttachLoadingPresenter()
        }
        return currentLoadingPresenter
    }

    open func createAndAttachLoadingPresenter() -> LoadingPresenter? {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.backgroundColor = UIColor.black.withAlphaComponent(0.33)
        activityIndicator.style = .gray
        activityIndicator.hidesWhenStopped = true

        return DefaultViewActivityIndicator(indicator: activityIndicator, parent: self.view)
    }

    public class DefaultViewActivityIndicator: LoadingPresenter {

        public init(indicator: UIActivityIndicatorView, parent: UIView) {
            self.indicator = indicator
            indicator.frame = parent.bounds
            parent.addSubview(indicator)
        }

        public let indicator: UIActivityIndicatorView

        public func showLoading(_ loading: Bool) {
            if loading {
                indicator.startAnimating()
            } else {
                indicator.stopAnimating()
            }
        }
    }

    public class DefaultWindowActivityIndicator: LoadingPresenter {

        public init(indicator: UIActivityIndicatorView) {
            self.indicator = indicator
        }

        public var indicator: UIActivityIndicatorView

        var current: UIActivityIndicatorView? {
            return UIApplication.shared.keyWindow?.subviews.last(where: { $0 is UIActivityIndicatorView }) as? UIActivityIndicatorView
        }

        public func showLoading(_ loading: Bool) {
            cleanOther()

            if loading {
                indicator.frame = UIApplication.shared.keyWindow!.bounds
                indicator.startAnimating()
                UIApplication.shared.keyWindow?.addSubview(indicator)
            } else {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }

        func cleanOther() {
            for other in UIApplication.shared.keyWindow?.subviews ?? [] where other is UIActivityIndicatorView && other != indicator {
                other.removeFromSuperview()
            }
        }
    }
}

extension UITableViewController {

    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        (currentLoadingPresenter as? DefaultViewActivityIndicator)?.indicator.frame = tableView.bounds
    }
}

extension UICollectionViewController {

    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        (currentLoadingPresenter as? DefaultViewActivityIndicator)?.indicator.frame = collectionView.bounds
    }
}
