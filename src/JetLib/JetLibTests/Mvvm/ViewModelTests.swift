//
//  Created on 02/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import JetLib

class ViewModelTests: XCTestCase {

    var viewModel: BaseTestViewModel!

    override func setUp() {
        viewModel = BaseTestViewModel()
    }

    override func tearDown() {
        viewModel?.onLoadCompleted = nil
        viewModel?.cleanTasks()
    }

    func testViewRelease() {
        var view: BaseTestView? = BaseTestView()
        viewModel.view = view
        XCTAssertTrue(viewModel.view === view)
        view = nil
        XCTAssertNil(viewModel.view)
    }

    func testTaskRelease() {
        let completed = expectation(description: "completed")
        var task: Task? = Task(1)
        viewModel.addTask(task!)
        viewModel.onLoadCompleted = { completed.fulfill() }


        weak var weakTask = task
        task = nil

        XCTAssertNotNil(weakTask)

        viewModel.reload()

        wait(completed)
        
        viewModel.cleanTasks()

        XCTAssertNil(weakTask)
    }

    func testViewModelRelease() {
        let task = Task.from { 1 }
        weak var weakViewModel = viewModel

        viewModel.addTask(task)
        viewModel.dataUpdateRequested(initiator: BaseTestViewModel()) // viewModel hold initiator untill updation finished

        XCTAssertNotNil(weakViewModel)

        viewModel = nil

        XCTAssertNil(weakViewModel)
    }

    func testCancelByOneTag() {
        let tag1 = DataTaskTag("tag1")
        let task1Exp = expectation(description: "task1Exp cancelled")
        let task2Exp = expectation(description: "task2Exp success")
        let task1 = Task.from { return true }.onCancel { task1Exp.fulfill() }
        let task2 = Task.from { return "123" }.onSuccess { _ in task2Exp.fulfill() }

        viewModel.submit(task: task1, tag: tag1)
        viewModel.submit(task: task2, tag: tag1)

        DispatchQueue.global().async(task2)

        wait(task1Exp, task2Exp)
    }

    func testManyDifferentTag() {
        let tag1 = DataTaskTag("tag1")
        let tag2 = DataTaskTag("tag2")
        let task1Exp = expectation(description: "task1Exp success")
        let task2Exp = expectation(description: "task2Exp success")
        let task1 = Task.from { return true }.onSuccess { _ in task1Exp.fulfill() }
        let task2 = Task.from  { return "123" }.onSuccess { _ in task2Exp.fulfill() }

        viewModel.submit(task: task1, tag: tag1)
        viewModel.submit(task: task2, tag: tag2)

        DispatchQueue.global().async(task1)
        DispatchQueue.global().async(task2)

        wait(task1Exp, task2Exp)
    }

    func testSubmitTask() {
        let exp1 = expectation(description: "submit")
        let exp2 = expectation(description: "submit finished")
        let task1 = Task.from { return true }.onSuccess { _ in exp1.fulfill() }

        viewModel.submit(task: task1).notify { _ in
            exp2.fulfill()
        }

        XCTAssertTrue(viewModel.loading)
        XCTAssertFalse(viewModel.canLoadData)

        DispatchQueue.global().async(task1)

        wait(exp1, exp2)
        XCTAssertFalse(viewModel.loading)
        XCTAssertTrue(viewModel.canLoadData)
    }

    func testMultiSubmit() {
        let exp1 = expectation(description: "submit1")
        let exp2 = expectation(description: "submit2")
        let exp3 = expectation(description: "submit finished")
        let task1 = Task.from { return true }.onSuccess { _ in exp1.fulfill() }
        let task2 = Task.from { return true }.onSuccess { _ in exp2.fulfill() }

        viewModel.submit(task: task1).notify { _ in
            exp3.fulfill()
        }
        viewModel.submit(task: task2)

        XCTAssertTrue(viewModel.loading)
        XCTAssertFalse(viewModel.canLoadData)

        DispatchQueue.global().async(task1)

        wait(exp1)
        XCTAssertTrue(viewModel.loading)
        XCTAssertFalse(viewModel.canLoadData)

        DispatchQueue.global().async(task2)

        wait(exp2, exp3)
        XCTAssertFalse(viewModel.loading)
        XCTAssertTrue(viewModel.canLoadData)
    }

    func testBeginLoading() {
        XCTAssertFalse(viewModel.loading)

        viewModel.addTask(Task.from { return 123 })
        viewModel.viewWillAppear(false)

        XCTAssertTrue(viewModel.loading)
    }

    func testFinishLoading() {
        let exp1 = expectation(description: "exp1")
        let task = Task.from { return 123 }.notify { _ in exp1.fulfill() }

        viewModel.addTask(task)
        viewModel.viewWillAppear(false)

        DispatchQueue.global().async(task)

        wait(exp1)

        XCTAssertFalse(viewModel.loading)
    }

    func testCancelLoadingAtDisappear() {
        let exp1 = expectation(description: "exp1")
        let task = Task.from { return 123 }.notify { _ in exp1.fulfill() }

        viewModel.addTask(task)
        viewModel.viewWillAppear(false)
        viewModel.viewDidDisappear(false)

        wait(exp1)

        XCTAssertFalse(viewModel.loading)
    }

    func testSimultaniuslyLoading() {
        let task = Task.from { return 123 }
        viewModel.addTask(task)

        viewModel.viewWillAppear(false)
        viewModel.viewWillAppear(true)

        XCTAssertEqual(viewModel.loadDataCallCount, 1)
    }

    func testSerialLoading() {
        let task = Task.from { return 123 }
        let completed = expectation(description: "completed")
        viewModel.addTask(task)
        viewModel.onLoadCompleted = { completed.fulfill() }

        viewModel.viewWillAppear(true)
        viewModel.viewDidDisappear(true)

        wait(completed)
        XCTAssert(task.isCancelled)

        viewModel.cleanTasks()
        viewModel.addTask(Task.from { return 123 })
        viewModel.viewWillAppear(true)

        XCTAssertEqual(viewModel.loadDataCallCount, 2)
    }

    func testReload() {
        let success = expectation(description: "canceled")
        let task = Task.from {
            return 123
        }.onSuccess { _ in
            success.fulfill()
        }

        viewModel.addTask(task)
        viewModel.reload()
        DispatchQueue.main.async(task)

        wait(success)
    }

    func testForceReload() {
        let canceled = expectation(description: "canceled")
        let task = Task.from {
            return 123
        }.onCancel {
            canceled.fulfill()
        }

        viewModel.addTask(task)

        viewModel.reload()
        viewModel.reload(force: true)

        wait(canceled)
    }
}

class BaseTestView: View, LoadingPresenter {

    var loading: Bool = false

    func showLoading(_ loading: Bool) {
        self.loading = loading
    }

    func sendViewAppearance(to delegate: ViewLifecycleDelegate, retain: Bool) {
    }
}

class BaseTestViewModel: ViewModel {

    weak var view: BaseTestView?

    private var loadings: [(ViewModel.DataLoader) -> Void] = []

    var loadDataCallCount: Int = 0
    var loadDataCompletedCount: Int = 0

    var onLoadCompleted: (() -> Void)? = nil

    func addTask<TData>(_ task: Task<TData>) {
        loadings.append({ try! $0.append(task)})
    }

    func cleanTasks() {
        loadings = []
    }

    override func willLoadData(loader: ViewModel.DataLoader) {
        loadDataCallCount += 1

        for loading in loadings {
            loading(loader)
        }
    }

    override func loadDataCompleted() {
        super.loadDataCompleted()
        loadDataCompletedCount += 1
        onLoadCompleted?()
    }
}
