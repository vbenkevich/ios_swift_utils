//
//  Created on 02/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol View: class {

    func sendViewAppearance(to delegate: ViewLifecycleDelegate, retain: Bool)
}

public protocol ViewLifecycleDelegate: class {

    func viewWillAppear(_ animated: Bool)

    func viewDidAppear(_ animated: Bool)

    func viewWillDisappear(_ animated: Bool)

    func viewDidDisappear(_ animated: Bool)
}

public protocol LoadingPresenter {

    func showLoading(_ loading: Bool)
}
