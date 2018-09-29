//
//  SlideMenuSampleController.swift
//  UtilsSamples
//
//  Created by Vladimir Benkevich on 29/09/2018.
//  Copyright © 2018 Vladimir Benkevich. All rights reserved.
//

import UIKit
import Utils

class SlideMenuSampleController: SlideMenuViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Menu", style: .done, target: self, action: #selector(handleShowMenu))

        let menu = MenuListController()
        menuController = menu
        currentController = menu.items[0].create()

        panMenuFromLeft = true
    }

    @objc func handleShowMenu(_ sender: Any) {
        self.showMenu()
    }

}

class MenuListController: UITableViewController, MenuController {

    weak var contentPresenter: ControllerPresenter?

    let items: [(name: String, create: () -> UIViewController)] = [
        (name: "Item1", create: { return UIViewController(title: "Item1", color: UIColor.red) }),
        (name: "Item2", create: { return UIViewController(title: "Item2", color: UIColor.green) }),
        (name: "Item3", create: { return UIViewController(title: "Item3", color: UIColor.blue) }),
        ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "itemCellId")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = items[indexPath.row].name
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        contentPresenter?.currentController = items[indexPath.row].create()
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true, completion: {
            print("menu has been dismissed")
        })
    }
}

extension UIViewController {

    convenience init(title: String, color: UIColor) {
        self.init()
        self.loadViewIfNeeded()
        self.title = title
        self.view.backgroundColor = color
    }
}
