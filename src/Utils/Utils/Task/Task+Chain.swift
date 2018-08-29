//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public extension Task {

    @discardableResult
    public func chain<K>(factory: @escaping (Task<T>) -> Task<K>) -> Task<K> {
        let tcs = Task<K>.Source()

        self.notify(DispatchQueue.global(qos: .userInitiated)) { _ in
            let task = factory(self)
            task.notify {
                try? tcs.setStatus($0.status)
            }
        }

        return tcs.task
    }
}
