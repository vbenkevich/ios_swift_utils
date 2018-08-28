//
//  HttpResponse.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

public class HttpError: Swift.Error, CustomStringConvertible {

    public static let badUrlFormat = HttpError("HttpError: badUrlFormat")
    public static let badParametersFormat = HttpError("HttpError: badParametersFormat")
    public static let badResponseType = HttpError("HttpError: badResponseType")
    public static let responseEmptyBody = HttpError("HttpError: responseEmptyBody")

    public init(_ description: String) {
        self.description = description
    }

    public var description: String
}

open class HttpResponse {

    required public init(_ request: URLRequest) {
        self.request = request
    }

    public let request: URLRequest

    public internal (set) var origin: URLResponse?

    public internal (set) var content: Data? {
        didSet {
            do {
                try process(content: content, response: origin, originError: error)
            } catch {
                self.error = error
            }
        }
    }

    public internal (set) var error: Error?

    open func process(content: Data?, response: URLResponse?, originError: Error?) throws {
    }
}

public extension URLResponse {

    func checkHttpSuccess(range: CountableRange<Int> = 200..<300) throws -> Bool {
        guard let httpResponse = self as? HTTPURLResponse  else {
            throw HttpError.badResponseType
        }

        let code = httpResponse.statusCode
        return range.contains(code)
    }
}
