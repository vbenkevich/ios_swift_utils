//
//  Created on 02/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

@objc
public protocol View: class {

    func sendViewAppearance(to delegate: ViewLifecycleDelegate, retain: Bool)
}

@objc
public protocol ViewLifecycleDelegate: class {

    func viewWillAppear(_ animated: Bool)

    func viewDidAppear(_ animated: Bool)

    func viewWillDisappear(_ animated: Bool)

    func viewDidDisappear(_ animated: Bool)
}

@objc
public protocol LoadingPresenter: class {

    func showLoading(_ loading: Bool)
}
