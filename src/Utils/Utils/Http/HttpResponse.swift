//
//  HttpResponse.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

open class HttpResponse {

    required public init(_ request: URLRequest) {
        self.request = request
    }

    open let request: URLRequest

    public internal (set) var origin: URLResponse?

    public internal (set) var data: Data? {
        didSet {
            do {
                try process(data: data, response: origin, originError: error)
            } catch {
                self.error = error
            }
        }
    }

    public internal (set) var error: Error?

    open func process(data: Data?, response: URLResponse?, originError: Error?) throws {
    }
}
