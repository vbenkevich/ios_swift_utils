//
//  Created on 28/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

class TestError: Error, Equatable {

    static func == (lhs: TestError, rhs: TestError) -> Bool {
        return lhs === rhs
    }
}
