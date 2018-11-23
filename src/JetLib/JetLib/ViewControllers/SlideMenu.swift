//
//  Created on 23/11/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation
import UIKit

open class SlideMenu: NSObject {

    public override init() {
        super.init()
        slideGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePanGesture))
            .set(edges: .left)
    }

    public var hostController: UIViewController? {
        didSet {
            if let gesture = slideGesture {
                oldValue?.view.removeGestureRecognizer(gesture)
                hostController?.view.addGestureRecognizer(gesture)
            }
        }
    }

    public var menuController: UIViewController!

    public var slideGesture: UIScreenEdgePanGestureRecognizer? {
        didSet {
            if let old = oldValue {
                hostController?.view.removeGestureRecognizer(old)
            }
            if let gesture = slideGesture {
                hostController?.view.addGestureRecognizer(gesture)
            }
        }
    }

    public var menuTransitioningAnimationTime: TimeInterval {
        get { return menuTransitioningDelegate.animationTime }
        set { menuTransitioningDelegate.animationTime = menuTransitioningAnimationTime }
    }

    public var menuMaxWidth: CGFloat {
        get { return menuTransitioningDelegate.menuMaxWidth }
        set { menuTransitioningDelegate.menuMaxWidth = newValue }
    }

    public var menuMinWidth: CGFloat {
        get { return menuTransitioningDelegate.menuMinWidth }
        set { menuTransitioningDelegate.menuMinWidth = newValue }
    }

    public var menuWidthRelative: CGFloat {
        get { return menuTransitioningDelegate.menuWidthRelative }
        set { menuTransitioningDelegate.menuWidthRelative = newValue }
    }

    public var menuSize: CGSize {
        return menuTransitioningDelegate.menuSize(for: hostController!.view.bounds.size)
    }

    fileprivate var menuTransitioningDelegate = TransitioningDelegate()

    fileprivate var interativePresent: UIPercentDrivenInteractiveTransition? {
        get { return menuTransitioningDelegate.interactivePresent }
        set { menuTransitioningDelegate.interactivePresent = newValue }
    }

    public func show(animated: Bool = true, completion: (() -> Void)? = nil) {
        menuController.modalPresentationStyle = .custom
        menuController.transitioningDelegate = menuTransitioningDelegate

        hostController!.present(menuController, animated: true, completion: completion)
    }

    public func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        menuController.dismiss(animated: animated, completion: completion)
    }

    @objc func handlePanGesture(gesture: UIScreenEdgePanGestureRecognizer) {
        gesture.update(transition: interativePresent, getPercent: {
            $0.x / menuSize.width
        }, getVelocity: {
            $0.x
        }, beginTransition: {
            self.interativePresent = UIPercentDrivenInteractiveTransition()
            self.show { self.interativePresent = nil }
        })
    }
}


extension SlideMenu {

    class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

        private let presentAnimationController: PresentAnimationController
        private let dismissAnimationController: DismissAnimationController

        override init() {
            self.presentAnimationController = PresentAnimationController(animationTime: animationTime)
            self.dismissAnimationController = DismissAnimationController(animationTime: animationTime)
            super.init()
        }

        var animationTime: TimeInterval = 0.300 {
            didSet {
                presentAnimationController.animationTime = animationTime
                dismissAnimationController.animationTime = animationTime
            }
        }

        var menuMaxWidth: CGFloat = 300

        var menuMinWidth: CGFloat = 150

        var menuWidthRelative: CGFloat = 0.67

        var interactiveDismiss: UIPercentDrivenInteractiveTransition?

        var interactivePresent: UIPercentDrivenInteractiveTransition?

        func menuSize(for containerSize: CGSize) -> CGSize {
            return CGSize(width: max(min(containerSize.width * menuWidthRelative, menuMaxWidth), menuMinWidth),
                          height: containerSize.height)
        }

        func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            return presentAnimationController
        }

        func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            return dismissAnimationController
        }

        func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
            return interactivePresent
        }

        func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
            return interactiveDismiss
        }

        func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
            return PresentationController(presented: presented, presenting: presenting, transitioningDelegate: self)
        }
    }

    class PresentAnimationController: NSObject, UIViewControllerAnimatedTransitioning {

        var animationTime: TimeInterval

        init(animationTime: TimeInterval) {
            self.animationTime = animationTime
            super.init()
        }

        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return animationTime
        }

        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let controller = transitionContext.viewController(forKey: .to)!
            let targetFrame = transitionContext.finalFrame(for: controller)
            controller.view.frame = targetFrame.offsetBy(dx: -targetFrame.width, dy: 0)

            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                controller.view.frame = targetFrame
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }

    class DismissAnimationController: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {

        var animationTime: TimeInterval

        init(animationTime: TimeInterval) {
            self.animationTime = animationTime
            super.init()
        }

        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return animationTime
        }

        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let controller = transitionContext.viewController(forKey: .from)!
            let sourceFrame = transitionContext.initialFrame(for: controller)

            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                controller.view.frame = sourceFrame.offsetBy(dx: -sourceFrame.width, dy: 0)
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }

    class PresentationController: UIPresentationController {

        let dimmingView: UIView
        let transitioningDelegate: TransitioningDelegate

        init(presented: UIViewController, presenting: UIViewController?, transitioningDelegate: TransitioningDelegate) {
            self.dimmingView = UIView()
            self.transitioningDelegate = transitioningDelegate

            super.init(presentedViewController: presented, presenting: presenting)

            dimmingView.backgroundColor = UIColor.black

            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            tapGesture.require(toFail: panGesture)
            dimmingView.addGestureRecognizer(tapGesture)
            dimmingView.addGestureRecognizer(panGesture)
        }

        override var shouldRemovePresentersView: Bool {
            return false
        }

        override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
            return transitioningDelegate.menuSize(for: parentSize)
        }

        override var frameOfPresentedViewInContainerView: CGRect {
            guard let bounds = containerView?.bounds else {
                return super.frameOfPresentedViewInContainerView
            }

            let viewSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: bounds.size)

            return CGRect(origin: bounds.origin, size: viewSize)
        }

        var interactiveTransition: UIPercentDrivenInteractiveTransition? {
            get { return transitioningDelegate.interactiveDismiss }
            set { transitioningDelegate.interactiveDismiss = newValue }
        }

        override func presentationTransitionWillBegin() {
            self.containerView!.addSubview(dimmingView)
            self.containerView!.addSubview(presentedViewController.view)
            self.dimmingView.alpha = 0.0

            presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0.5
            })
        }

        override func presentationTransitionDidEnd(_ completed: Bool) {
            if !completed {
                dimmingView.removeFromSuperview()
            }
        }

        override func dismissalTransitionWillBegin() {
            presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0
            })
        }

        override func dismissalTransitionDidEnd(_ completed: Bool) {
            if completed {
                dimmingView.removeFromSuperview()
                presentedViewController.view.removeFromSuperview()
            }
        }

        override func containerViewWillLayoutSubviews() {
            dimmingView.frame = containerView!.bounds
            presentedView?.frame = frameOfPresentedViewInContainerView
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            presentedViewController.dismiss(animated: true){}
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            gesture.update(transition: interactiveTransition, getPercent: {
                -$0.x / transitioningDelegate.menuSize(for: gesture.view!.bounds.size).width
            }, getVelocity: {
                -$0.x
            }, beginTransition: {
                self.interactiveTransition = UIPercentDrivenInteractiveTransition()
                self.presentedViewController.dismiss(animated: true) { self.interactiveTransition = nil }
            })
        }
    }
}

extension UIScreenEdgePanGestureRecognizer {

    func set(edges: UIRectEdge) -> UIScreenEdgePanGestureRecognizer {
        self.edges = edges
        return self
    }
}

extension UIPanGestureRecognizer {

    func update(transition: UIPercentDrivenInteractiveTransition?,
                getPercent:  (_ translate: CGPoint) -> CGFloat,
                getVelocity: (_ original: CGPoint) -> CGFloat,
                beginTransition: () -> Void) {
        let translate = self.translation(in: view)

        if state == .began {
            beginTransition()
        } else if state == .changed {
            transition?.update(getPercent(translate))
        } else if state == .cancelled || state == .ended {
            let velocity = getVelocity(self.velocity(in: view))
            let percents = getPercent(translate)
            if velocity < 0 || (velocity == 0 && percents < 0.5) {
                transition?.cancel()
            } else {
                transition?.finish()
            }
        }
    }
}
