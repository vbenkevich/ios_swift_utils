//
//  CommandSampleController.swift
//
//  Created by Vladimir Benkevich on 27/07/2018.
//  Copyright © 2018
//

import UIKit
import Utils

class CommandSampleController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!

    var viewModel = ViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.view = self
        button.command = viewModel.command
        button.command = viewModel.testWorkItemCommand
    }
}

class ViewModel {

    lazy var command = ActionCommand(self) {
        $0.request()
    }

    lazy var testWorkItemCommand = ActionCommand {
        var semaphore = DispatchSemaphore(value: 0)

        var workItem = DispatchWorkItem {
            semaphore.wait()
        }

        workItem.notify(queue: DispatchQueue.main) {
            print("completed")
        }

        DispatchQueue.global().async(execute: workItem)

        workItem.cancel()
        print("cancel")

        semaphore.signal()
        print("signal")
    }

    weak var view: CommandSampleController?

    var text: String? {
        didSet {
            view?.label.text = text
        }
    }

    func request() {
        Service().fetchDataQueue(test: "1").notify {
            self.text = $0.result!
        }.chain { _ in
            return Service().fetchDataTcs(test: "2")
        }.notify {
            self.text = $0.result!
        }
    }
}

class Service {

    func fetchDataTcs<T>(test: T) -> Task<T> {
        let tcs = Task<T>.Source()

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            try? tcs.complete(test)
        }

        return tcs.task
    }

    func fetchDataQueue<T>(test: T) -> Task<T> {
        let task = Task<T> { return test }
        return DispatchQueue.global().async(task, after: .seconds(1))
    }

    struct test: Error {
    }
}
