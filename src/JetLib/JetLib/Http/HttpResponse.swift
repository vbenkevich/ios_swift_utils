//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

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
            throw HttpException.badResponseType
        }

        let code = httpResponse.statusCode
        return range.contains(code)
    }
}


public class HttpException: Exception {
}

extension HttpException {

    static let badUrlFormat = HttpException("Bad url format")
    static let badParametersFormat = HttpException("Bad parameters format")
    static let badResponseType = HttpException("Bad response type")
    static let responseEmptyBody = HttpException("Empty response body")
}
