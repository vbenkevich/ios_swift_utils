//
//  Created on 08/01/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

public extension Task {

    static func delay(_ milliseconds: Int) -> Task<Void> {
        return Task.delay(.milliseconds(milliseconds))
    }

    static func delay(_ interval: DispatchTimeInterval) -> Task<Void> {
        return DispatchQueue.global().execute(after: interval){}
    }

    func delay(_ milliseconds: Int) -> Task {
        return delay(.milliseconds(milliseconds))
    }

    func delay(_ interval: DispatchTimeInterval) -> Task {
        return self.chain(nextTask: { _ in
            Task.delay(interval)
        }).chain { _ in
            return self
        }
    }

    func delayOnSuccess(_ interval: DispatchTimeInterval) -> Task {
        return self.chainOnSuccess(nextTask: { _ in
            DispatchQueue.global().execute(after: interval){}
        }).chain { _ in
            return self
        }
    }
}
