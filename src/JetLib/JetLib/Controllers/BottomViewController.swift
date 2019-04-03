//
//  Created on 03/04/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

public protocol BottomViewControllerDelegate: class {

    func sizeDidChange(_ controller: BottomViewController, old: BottomViewController.Size, new: BottomViewController.Size)

    func sizeChanging(_ controller: BottomViewController, from: BottomViewController.Size, to: BottomViewController.Size, fraction: CGFloat)
}

open class BottomViewController: UIViewController {

    public enum Size: Equatable {
        case absolute(dp: CGFloat)
        case relative(fraction: CGFloat)
        case complex(dp: CGFloat, fraction: CGFloat)

        static let half: Size = .relative(fraction: 0.5)
        static let zero: Size = .complex(dp: 0, fraction: 0)
    }

    public private (set) var size: Size = .half {
        didSet {
            updateHeightConstraint(size)
            delegate?.sizeDidChange(self, old: oldValue, new: size)
        }
    }

    public var sizes: [Size] = [.half, .zero] {
        didSet {
            if sizes.count < 1 { preconditionFailure("have to be at leas one size") }
        }
    }

    public weak var delegate: BottomViewControllerDelegate?

    public weak var contentController: UIViewController? {
        didSet {
            if let old = oldValue {
                if old.isViewLoaded {
                    old.view.removeFromSuperview()
                }
                old.removeFromParent()
            }

            if let content = contentController {
                content.removeFromParent()
                addChild(content)
            }

            if isViewLoaded {
                contentController?.loadViewIfNeeded()
                reloadContent()
            }
        }
    }

    public var dimmingView: UIView? {
        didSet {
            if isViewLoaded {
                reloadContent()
            }
            oldValue?.removeFromSuperview()
        }
    }

    private var heightConstraint: NSLayoutConstraint? {
        didSet {
            if let old = oldValue {
                old.isActive = false
                contentController?.view.removeConstraint(old)
            }
            heightConstraint?.isActive = true
        }
    }

    private var currentPanning: PanGestureHelper?

    open override func viewDidLoad() {
        super.viewDidLoad()
        reloadContent()
    }

    public func setSize(_ newSize: Size, animated: Bool) {
        guard animated, let constraint = heightConstraint else {
            size = newSize
            return
        }

        constraint.constant = size.dimemsions.constant + newSize.height(in: view) - size.height(in: view)

        UIView.animate(withDuration: 0.200, delay: 0, options: [.curveEaseOut], animations: { [view] in
            view!.layoutIfNeeded()
            }, completion: { _ in
                self.size = newSize
        })
    }


    public func link(with gesture: UIPanGestureRecognizer) {
        gesture.addTarget(self, action: #selector(handleChildPan))
    }

    private func updateHeightConstraint(_ size: Size) {
        guard let content = contentController?.view else {
            return
        }

        heightConstraint = content.heightAnchor.constraint(equalTo: view.heightAnchor,
                                                           multiplier: size.dimemsions.multiplier,
                                                           constant: size.dimemsions.constant)
    }

    private func reloadContent() {
        if let dimming = dimmingView {
            dimming.frame = view.bounds
            dimming.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(dimming)
        }

        if let content = contentController?.view {
            view.addSubview(content)
            content.translatesAutoresizingMaskIntoConstraints = false
            content.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            content.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            content.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            updateHeightConstraint(size)
        }

        delegate?.sizeDidChange(self, old: size, new: size)
    }

    @objc
    private func handleChildPan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            currentPanning = PanGestureHelper(gesture, initial: size, allSizes: sizes, root: view)
            currentPanning?.scrollView = gesture.view as? UIScrollView
        case .cancelled, .failed:
            heightConstraint?.constant = size.dimemsions.constant
        case .ended:
            updateSizeState()
        default:
            let info = currentPanning!.info
            heightConstraint?.constant = info.sizeOffset
            currentPanning?.corectScroll(info: info)
            delegate?.sizeChanging(self, from: info.from, to: info.to, fraction: info.fraction)
        }
    }

    private func updateSizeState() {
        let actualHeight = size.height(in: view) + heightConstraint!.constant - size.dimemsions.constant
        let nextSize = sizes.nearestSize(for: actualHeight, in: view)

        setSize(nextSize.size, animated: true)
    }
}

private extension Array where Element == BottomViewController.Size {

    func nearestSize(for actualHeight: CGFloat, in view: UIView) -> SizeInfo {
        let nearest = nearestSizes(for: actualHeight, in: view)

        if (nearest.first.height - actualHeight) < (actualHeight - nearest.second.height) {
            return nearest.first
        } else {
            return nearest.second
        }
    }

    func nearestSizes(for actualHeight: CGFloat, in view: UIView) -> (first: SizeInfo, second: SizeInfo) {
        let sorted = sortedByHeight(in: view)

        var first = sorted.first!
        var second = sorted.last!

        for item in sorted {
            if actualHeight > item.height {
                second = item
                break
            } else {
                first = item
            }
        }

        return (first: first, second: second)
    }

    func sortedByHeight(in view: UIView) -> [SizeInfo] {
        return map { SizeInfo(size: $0, height: $0.height(in: view)) }.sorted { $0.height > $1.height }
    }
}

private struct SizeInfo: Equatable {
    let size: BottomViewController.Size
    let height: CGFloat
}

private extension BottomViewController {

    class PanGestureHelper {

        private let initialPt: CGFloat
        private let root: UIView
        private let size: Size
        private let gesture: UIPanGestureRecognizer
        private let allSizes: [Size]
        private let maxConstant: CGFloat
        private let minConstant: CGFloat

        private var from: SizeInfo

        init(_ gesture: UIPanGestureRecognizer, initial: Size, allSizes: [Size], root: UIView) {
            self.root = root
            self.size = initial
            self.gesture = gesture
            self.allSizes = allSizes

            let heights = allSizes.sortedByHeight(in: root)

            initialPt = gesture.location(in: root).y
            maxConstant = initial.dimemsions.constant + heights.first!.height - initial.height(in: root)
            minConstant = initial.dimemsions.constant + heights.last!.height - initial.height(in: root)
            from = SizeInfo(size: initial, height: initial.height(in: root))
        }

        var scrollView: UIScrollView?

        var constant: CGFloat {
            var diff = initialPt - gesture.location(in: root).y

            if let offset = scrollView?.contentOffset.y, let inset = scrollView?.totalContentInsets.top {
                diff += offset + inset
            }

            return max(min(maxConstant, size.dimemsions.constant + diff), minConstant)
        }

        var currentHeight: CGFloat {
            return size.height(in: root) + constant - size.dimemsions.constant
        }

        var info: PanningInfo {
            let actualHeight = size.height(in: root) + constant - size.dimemsions.constant
            let nearest = allSizes.nearestSizes(for: actualHeight, in: root)
            let to: SizeInfo!

            if from != nearest.first {
                from = nearest.first
                to = nearest.second
            } else {
                from = nearest.second
                to = nearest.first
            }

            let offset = constant

            return PanningInfo(from: from.size,
                               to: to.size,
                               fraction: (from.height - actualHeight) / (from.height - to.height),
                               sizeOffset: offset)
        }

        func corectScroll(info: PanningInfo) {
            guard let scroll = scrollView, info.sizeOffset != minConstant, info.sizeOffset != maxConstant else {
                return
            }

            scroll.contentOffset.y = -scroll.totalContentInsets.top
        }
    }

    struct PanningInfo {
        let from: Size
        let to: Size
        let fraction: CGFloat
        let sizeOffset: CGFloat
    }
}

private extension BottomViewController.Size {

    var dimemsions: Dimensions {
        switch self {
        case .absolute(let dp):
            return Dimensions(constant: dp, multiplier: 0)
        case .relative(let fraction):
            return Dimensions(constant: 0, multiplier: fraction)
        case .complex(let dp, let fraction):
            return Dimensions(constant: dp, multiplier: fraction)
        }
    }

    func height(in view: UIView) -> CGFloat {
        let dim = dimemsions
        return view.bounds.height * dim.multiplier + dim.constant
    }

    struct Dimensions {
        let constant: CGFloat
        let multiplier: CGFloat
    }
}
