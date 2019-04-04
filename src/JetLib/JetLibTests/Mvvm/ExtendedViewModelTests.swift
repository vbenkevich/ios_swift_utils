//
//  Created on 27/12/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation
import XCTest
@testable import JetLib

class ExtendedViewModelTests: XCTestCase {

    override func setUp() {
        UIViewController.swizzleViewAppearances()
    }

    override func tearDown() {
        AlertPresenterDefaults.instance = AlertPresenterDefaults()
    }

    func testLifecycle() {
        let viewModel = ViewModel()
        let controller = TestController()
        let sendViewAppearance = expectation(description: "sendViewAppearance")
        sendViewAppearance.expectedFulfillmentCount = 2

        var retainVm = true

        controller.sendViewAppearance = { delegate, retain in
            XCTAssert(delegate === viewModel)
            XCTAssertEqual(retain, retainVm)
            sendViewAppearance.fulfill()
        }

        viewModel.lifecycle(source: controller)
        retainVm = false
        viewModel.lifecycle(source: controller, isSourceRetainViewModel: retainVm)

        wait(sendViewAppearance)
    }

    func testSetAlertsPresenter() {
        let viewModel = ExtendedViewModel()
        var alertsPresenter: AlertPresenter! = UIViewController()
        weak var weakPresenter = alertsPresenter

        viewModel.alerts(presenter: alertsPresenter)

        XCTAssert(alertsPresenter === viewModel.alertPresenter)

        alertsPresenter = nil

        XCTAssertNil(weakPresenter)
    }

    func testSubmitErrorAlert() {
        let viewModel = ExtendedViewModel()
        let alertPresenter = TestController()
        let msg = "TestError"
        let exp = expectation(description: "error alert")
        let errTitle = "new error title"
        let okButton = "new ok"
        AlertPresenterDefaults.instance.errorTitle = errTitle
        AlertPresenterDefaults.instance.okButtonText = okButton

        alertPresenter.showAlert = { title, message, ok, style, cancel, _ , _ in
            XCTAssertEqual(title, errTitle)
            XCTAssertEqual(message, msg)
            XCTAssertEqual(ok, okButton)
            XCTAssertEqual(style, .default)
            XCTAssertNil(cancel)
            exp.fulfill()
        }

        viewModel.alerts(presenter: alertPresenter)
        viewModel.submit(task: Task<Void>(Exception(msg, nil)))

        wait(exp)
    }

    func testLoadingErrorAlert() {
        let viewModel = TestViewModel()
        let alertPresenter = TestController()
        let msg = "TestError"
        let exp = expectation(description: "error alert")
        let errTitle = "new error title"
        let okButton = "new ok"

        AlertPresenterDefaults.instance.errorTitle = errTitle
        AlertPresenterDefaults.instance.okButtonText = okButton

        viewModel.willLoadData = {
            try! $0.append(Task<Int>(Exception(msg, nil)))
        }

        alertPresenter.showAlert = { title, message, ok, style, cancel, _ , _ in
            XCTAssertEqual(title, errTitle)
            XCTAssertEqual(message, msg)
            XCTAssertEqual(ok, okButton)
            XCTAssertEqual(style, .default)
            XCTAssertNil(cancel)
            exp.fulfill()
        }

        viewModel.alerts(presenter: alertPresenter)
        viewModel.reload(force: true)

        wait(exp)
    }

    func testExtendedViewModelAsAlertPresenter() {
        let viewModel = ExtendedViewModel()
        let presenter1 = TestController()
        let presenter2 = TestController()

        let failOk = expectation(description: "failOk")
        let successOk = expectation(description: "successOk")
        let failDelete = expectation(description: "failDelete")
        let successDelete = expectation(description: "successDelete")

        viewModel.showAlert(title: "t", message: "m", ok: "ok", cancel: "c").onFail { _ in failOk.fulfill() }
        viewModel.showAlert(title: "t", message: "m", delete: "d", cancel: "c").onFail { _ in failDelete.fulfill() }

        viewModel.alertPresenter = presenter1
        presenter1.showAlert = { title, message, ok, style, cancel, _ , _ in
            XCTAssertEqual(title, "t1")
            XCTAssertEqual(message, "m1")
            XCTAssertEqual(ok, "d1")
            XCTAssertEqual(style, .destructive)
            XCTAssertEqual(cancel, "c1")
            successDelete.fulfill()
        }

        viewModel.showAlert(title: "t1", message: "m1", delete: "d1", cancel: "c1")

        viewModel.alertPresenter = presenter2
        presenter2.showAlert = { title, message, ok, style, cancel, _ , _ in
            XCTAssertEqual(title, "t2")
            XCTAssertEqual(message, "m2")
            XCTAssertEqual(ok, "o2")
            XCTAssertEqual(style, .default)
            XCTAssertEqual(cancel, "c2")
            successOk.fulfill()
        }

        viewModel.showAlert(title: "t2", message: "m2", ok: "o2", cancel: "c2")

        wait(failOk, failDelete, successOk, successDelete)
    }

    func testSetLoading() {
        let viewModel  = ExtendedViewModel()
        var loadingPresenter: LoadingPresenter! = UIViewController()
        weak var weakPresenter = loadingPresenter

        viewModel.loadings(presenter: loadingPresenter)

        XCTAssert(loadingPresenter === viewModel.loadingPresenter)

        loadingPresenter = nil

        XCTAssertNil(weakPresenter)
    }

    func testShowAppearingLoading() {
        let viewModel = TestViewModel()
        let controller = TestController()

        viewModel.wire(with: controller)

        let semaphore = DispatchSemaphore(value: 1)
        let loadingExpectation = expectation(description: "loading")
        let completedExpectation = expectation(description: "completed")

        viewModel.willLoadData = {
            try! $0.append(DispatchQueue.global().async(Task(execute: {
                semaphore.wait()
            })))
        }

        controller.showLoading = {
            if $0 {
                loadingExpectation.fulfill()
            } else {
                completedExpectation.fulfill()
            }
        }

        controller.beginAppearanceTransition(true, animated: false)

        wait(loadingExpectation)
        semaphore.signal()
        wait(completedExpectation)
    }

    func testShowSubmitLoading() {
        let viewModel = TestViewModel()
        let controller = TestController()
        controller.createPresenter = {
            return UIViewController.DefaultWindowActivityIndicator(indicator: UIActivityIndicatorView())
        }

        viewModel.wire(with: controller)

        let semaphore = DispatchSemaphore(value: 1)
        let loadingExpectation = expectation(description: "loading")
        let completedExpectation = expectation(description: "completed")

        controller.showLoading = {
            if $0 {
                loadingExpectation.fulfill()
            } else {
                completedExpectation.fulfill()
            }
        }

        viewModel.submit(task: DispatchQueue.global().async(Task(execute: { semaphore.wait() })))

        wait(loadingExpectation)
        semaphore.signal()
        wait(completedExpectation)
    }

    class TestViewModel: ExtendedViewModel {

        lazy var willLoadData = stub(self.willLoadData)

        override func willLoadData(loader: ViewModel.DataLoader) {
            willLoadData?(loader)
        }
    }

    class TestController: UIViewController {

        lazy var sendViewAppearance = stub(self.sendViewAppearance)
        lazy var showAlert = stub(self.showAlertImpl)
        lazy var showLoading = stub(self.showLoading)
        lazy var createPresenter = stub(self.createAndAttachLoadingPresenter)

        @objc override func createAndAttachLoadingPresenter() -> LoadingPresenter? {
            return createPresenter?() ?? super.createAndAttachLoadingPresenter()
        }

        override func sendViewAppearance(to delegate: ViewLifecycleDelegate, retain: Bool) {
            sendViewAppearance?(delegate, retain)
            super.sendViewAppearance(to: delegate, retain: retain)
        }

        override func showAlertImpl(title: String?, message: String?, ok: String, okStyle: UIAlertAction.Style, cancel: String?, handleOk: @escaping () -> Void, handleCancel: @escaping () -> Void) {
            showAlert?(title, message, ok, okStyle, cancel, handleOk, handleCancel)
        }

        override func showLoading(_ loading: Bool) {
            showLoading?(loading)
            super.showLoading(loading)
        }
    }
}
