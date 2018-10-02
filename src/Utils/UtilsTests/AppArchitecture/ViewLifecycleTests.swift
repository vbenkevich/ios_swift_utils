//
//  Created on 02/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import Utils

class ViewLifecycleTests: XCTestCase {

    override func setUp() {
        UIViewController.swizzleViewAppearances()
    }

    override func tearDown() {
    }

    func testAddDelegate() {
        let view = UIViewController()
        let delegate = TestViewLifecycleDelegate()
        let anotherDelegate = TestViewLifecycleDelegate()

        view.add(delegate)
        XCTAssertEqual(view.lifecycleDelegates.count, 1)

        view.add(delegate)
        XCTAssertEqual(view.lifecycleDelegates.count, 1)

        view.add(anotherDelegate)
        XCTAssertEqual(view.lifecycleDelegates.count, 2)
    }

    func testRemoveDelegate() {
        let view = UIViewController()
        let delegate = TestViewLifecycleDelegate()
        let anotherDelegate = TestViewLifecycleDelegate()

        view.add(delegate)
        XCTAssertEqual(view.lifecycleDelegates.count, 1)

        view.remove(anotherDelegate)
        XCTAssertEqual(view.lifecycleDelegates.count, 1)

        view.remove(delegate)
        XCTAssertEqual(view.lifecycleDelegates.count, 0)
    }

    func testStrongRefDelegate() {
        let view = UIViewController()
        var delegate: TestViewLifecycleDelegate? = TestViewLifecycleDelegate()
        weak var weakDelegate = delegate

        view.add(delegate!, strongReference: true)
        delegate = nil

        XCTAssertNotNil(weakDelegate)
    }

    func testWaekRefDelegate() {
        let view = UIViewController()
        var delegate: TestViewLifecycleDelegate? = TestViewLifecycleDelegate()
        weak var weakDelegate = delegate

        view.add(delegate!, strongReference: false)
        delegate = nil

        XCTAssertNil(weakDelegate)
    }

    func testSwizzling() {
        let view = UIViewController()
        let willAppear = expectation(description: "willAppear")
        let didAppear = expectation(description: "didAppear")
        let willDisappear = expectation(description: "willDisappear")
        let didDisappear = expectation(description: "didDisapper")

        let delegate = TestViewLifecycleDelegate()
        delegate.onWillAppear = {
            XCTAssertEqual($0, true)
            willAppear.fulfill()
        }
        delegate.onDidAppear = {
            XCTAssertEqual($0, true)
            didAppear.fulfill()
        }
        delegate.onWillDisappear = {
            XCTAssertEqual($0, false)
            willDisappear.fulfill()
        }
        delegate.onDidDisappear = {
            XCTAssertEqual($0, false)
            didDisappear.fulfill()
        }

        view.add(delegate, strongReference: true)

        view.beginAppearanceTransition(true, animated: true)
        view.endAppearanceTransition()
        view.beginAppearanceTransition(false, animated: false)
        view.endAppearanceTransition()

        wait(for: [willAppear, didAppear, willDisappear, didDisappear], timeout: 1, enforceOrder: true)
    }
}

class TestViewLifecycleDelegate: ViewLifecycleDelegate {

    var onWillAppear: (Bool) -> Void = { _ in }
    var onDidAppear: (Bool) -> Void = { _ in }
    var onWillDisappear: (Bool) -> Void = { _ in }
    var onDidDisappear: (Bool) -> Void = { _ in }

    func viewWillAppear(_ animated: Bool) {
        onWillAppear(animated)
    }

    func viewDidAppear(_ animated: Bool) {
        onDidAppear(animated)
    }

    func viewWillDisappear(_ animated: Bool) {
        onWillDisappear(animated)
    }

    func viewDidDisappear(_ animated: Bool) {
        onDidDisappear(animated)
    }
}
