//
//  TestError.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

class TestError: Error, Equatable {

    static func == (lhs: TestError, rhs: TestError) -> Bool {
        return lhs === rhs
    }
}
