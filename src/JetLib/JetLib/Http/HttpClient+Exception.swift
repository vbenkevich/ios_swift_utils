//
//  Created on 25/12/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public extension HttpClient {

    class DefaultErrorDecoder: HttpResponseErrorDecoder {

        public var errorMessageDecoder: ((Data?) -> String?)? = { String(data: $0) }

        public func throwError(from response: Response) throws {
            guard try response.response?.checkHttpSuccess() != true else {
                return
            }

            if let error = response.error {
                throw HttpException(error: error)
            }

            if let message = errorMessageDecoder?(response.content) {
                throw HttpException(message: message, response: response.response, data: response.content)
            }

            if response.response != nil {
                throw HttpException(response: response.response, data: response.content)
            }

            throw HttpException(NSLocalizedString("Unknown error", comment: ""))
        }
    }
}

extension URLResponse {

    var httpStatusCode: Int? {
        return (self as? HTTPURLResponse)?.statusCode
    }

    var statusCodeMessage: String? {
        guard let code = httpStatusCode else { return nil }

        switch code {
        case 404:   return NSLocalizedString("Not Found", comment: "")
        case 503:   return NSLocalizedString("Service Unavailable", comment: "")
        default:    return NSLocalizedString("Status code", comment: "") + ": \(code)"
        }
    }
}

open class HttpException: Exception {

    public let statusCode: Int?
    public let body: Data?

    open var isNoInternet: Bool {
        return false
    }

    open var isRequestTimeOut: Bool {
        return (source as? URLError)?.code == URLError.timedOut
    }

    public override init(_ message: String? = nil, _ error: Error? = nil) {
        self.statusCode = nil
        self.body = nil
        super.init(message, error)
    }

    public init(error: Error?) {
        self.statusCode = nil
        self.body = nil
        super.init((error as? URLError)?.localizedDescription, error)
    }

    public init(response: URLResponse?, data: Data?) {
        self.statusCode = response?.httpStatusCode
        self.body = data
        super.init(response?.statusCodeMessage, nil)
    }

    public init(message: String, response: URLResponse?, data: Data?) {
        self.statusCode = response?.httpStatusCode
        self.body = data
        super.init(message, nil)
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

public extension HttpException {

    static let badUrlFormat = HttpException("Bad url format")
    static let badParametersFormat = HttpException("Bad parameters format")
    static let badResponseType = HttpException("Bad response type")
    static let responseEmptyBody = HttpException("Empty response body")
    static let responseNotEmptyBody = HttpException("Not empty response body")
}

public extension String {

    init?(data: Data?) {
        guard let data = data else { return nil }
        self.init(data: data, encoding: .utf8)
    }
}
