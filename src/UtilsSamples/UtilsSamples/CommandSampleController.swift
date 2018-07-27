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
    }
}

class ViewModel {
    var counter = 0

    lazy var command = ActionCommand(self) {
        $0.request()
    }

    weak var view: CommandSampleController?

    var text: String? {
        didSet {
            view?.label.text = text
        }
    }

    var newText: String {
        defer { counter += 1 }
        return counter.description
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
        return DispatchQueue.global().async(Task { return test }, after: .seconds(1))
    }

    struct test: Error {
    }
}
