//
//  Created on 31/10/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol ValueConverter {
    associatedtype From
    associatedtype To

    func convertForward(_ value: From?) -> To?
    func convertBack(_ value: To?) -> From?
}

