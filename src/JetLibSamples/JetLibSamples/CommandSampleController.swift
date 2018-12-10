//
//  CommandSampleController.swift
//
//  Created by Vladimir Benkevich on 27/07/2018.
//  Copyright © 2018
//

import UIKit
import JetLib

class CommandSampleController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!

    var viewModel: CommandSampleViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = CommandSampleViewModel()
        add(viewModel)

        try! label.bind(to: viewModel.textProperty)

        button.command = viewModel.command
    }
}

class CommandSampleViewModel: ViewModel {

    override init() {
        super.init()

        command = ActionCommand(self, execute: {
            $0.doSomething()
        }, canExecute: {
            $0.canLoadData
        })
    }

    var command: ActionCommand!

    var textProperty = Observable("")

    func doSomething() {
        let complexRequest = submit(task:  Service().fetchDataQueue(test: "1").notify(DispatchQueue.main) {
            self.textProperty.value = $0.result
        }.chain { _ in
            return Service().fetchDataTcs(test: "2")
        }.notify(DispatchQueue.main) {
            self.textProperty.value = $0.result
        })

        complexRequest.notify { [weak self] (_) in
            self?.command.invalidate()
        }
    }
}

class Service {

    func fetchDataTcs<T>(test: T) -> Task<T> {
        let tcs = Task<T>.Source()

        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
            try? tcs.complete(test)
        }

        return tcs.task
    }

    func fetchDataQueue<T>(test: T) -> Task<T> {
        let task = Task<T>(execute: {
            return test
        })
        return DispatchQueue.global().async(task, after: .seconds(1))
    }

    struct test: Error {
    }
}
