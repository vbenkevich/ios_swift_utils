//
//  Created on 02/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol View: class {
}

public protocol ViewLifecycleAware: class {

    func viewWillAppear(_ animated: Bool)

    func viewDidAppear(_ animated: Bool)

    func viewWillDisappear(_ animated: Bool)

    func viewDidDisappear(_ animated: Bool)
}

public protocol DataLoadingPresenter {

    func showLoading(_ loading: Bool)
}
