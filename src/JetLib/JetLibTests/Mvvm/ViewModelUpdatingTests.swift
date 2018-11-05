//
//  Created on 05/11/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import JetLib

class ViewModelUpdatingTests: XCTestCase {

    var viewModel: TestViewModel!
    var initiator: TestInitiator!
    var loadTaskSource: Task<Void>.Source!

    override func setUp() {
        super.setUp()

        viewModel = TestViewModel()
        initiator = TestInitiator()
        loadTaskSource = Task<Void>.Source()
        viewModel.loadingTask = loadTaskSource.task
    }


    override func tearDown() {
        super.tearDown()
        viewModel = nil
        initiator = nil
        loadTaskSource = nil
    }

    func testBasicUpdate() {
        let started = expectation(description: "started")
        let completed = expectation(description: "completed")

        initiator.started = { started.fulfill() }
        initiator.completed = { completed.fulfill() }
        initiator.aborted = { XCTFail() }

        viewModel.dataUpdateRequested(initiator: initiator)

        wait(started)

        try! loadTaskSource.complete()

        wait(completed)
    }

    func testDoubleUpdate() {
        let started = expectation(description: "started")
        let completed = expectation(description: "completed")
        let aborted = expectation(description: "aborted")

        initiator.started = { started.fulfill() }
        initiator.completed = { completed.fulfill() }
        initiator.aborted = { aborted.fulfill() }

        viewModel.dataUpdateRequested(initiator: initiator)

        wait(started)

        viewModel.dataUpdateRequested(initiator: initiator)

        wait(aborted)

        try! loadTaskSource.complete()

        wait(completed)
    }

    func testDispatchGroupAsUpdateInitiator() {
        let started = expectation(description: "started")
        let completed = expectation(description: "completed")

        initiator.started = { started.fulfill() }
        initiator.completed = { completed.fulfill() }
        initiator.aborted = { XCTFail() }

        let secondViewModel = TestViewModel()
        let secondLoadSource = TaskCompletionSource<Void>()
        secondViewModel.loadingTask = secondLoadSource.task

        [viewModel, secondViewModel].dataUpdateRequested(initiator: initiator)

        wait(started)
        XCTAssertFalse(initiator.isCompleted)

        try! loadTaskSource.complete()
        XCTAssertFalse(initiator.isCompleted)

        try! secondLoadSource.complete()
        wait(completed)
    }

    func testDispatchGroupAsUpdateInitiatorDoubleUpdateOnlyOneCompleted() {
        let completed = expectation(description: "completed")
        
        initiator.started = { }
        initiator.completed = { completed.fulfill() }
        initiator.aborted = { }

        let secondViewModel = TestViewModel()
        let secondLoadSource = TaskCompletionSource<Void>()
        secondViewModel.loadingTask = secondLoadSource.task

        [viewModel, secondViewModel].dataUpdateRequested(initiator: initiator)
        [viewModel, secondViewModel].dataUpdateRequested(initiator: initiator)

        try! loadTaskSource.complete()
        XCTAssertFalse(initiator.isCompleted)

        try! secondLoadSource.complete()
        wait(completed)
    }

    func testRefreshControl() {
        let control = TestUIRefreshControl()
        let begin = expectation(description: "started")
        let end = expectation(description: "ended")

        control.begin = { begin.fulfill() }
        control.end = { end.fulfill() }

        viewModel.dataUpdateRequested(initiator: control)
        wait(begin)

        try! loadTaskSource.complete()
        wait(end)
    }

    class TestInitiator: UpdateInitiator {
        var started: (() -> Void)!
        var completed: (() -> Void)!
        var aborted: (() -> Void)!

        var isCompleted: Bool = false

        func updateStarted() {
            started()
        }

        func updateCompleted() {
            isCompleted = true
            completed()
        }

        func updateNotStarted() {
            aborted()
        }
    }

    class TestUIRefreshControl: UIRefreshControl {

        var begin: (() -> Void)!
        var end: (() -> Void)!

        override func beginRefreshing() {
            super.beginRefreshing()
            begin()
        }

        override func endRefreshing() {
            super.endRefreshing()
            end()
        }
    }

    class TestViewModel: ViewModel {
        var loadingTask: Task<Void>!
        override func loadData() -> NotifyCompletion {
            load(task: loadingTask)
            return super.loadData()
        }
    }
}
