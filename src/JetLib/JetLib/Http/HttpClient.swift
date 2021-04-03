//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol URLRequestAdapter {

    func adapt(origin: URLRequest) -> URLRequest
}

public struct Response {
    public let request: URLRequest
    public let content: Data?
    public let response: URLResponse?
    public let error: Error?
}

public protocol ApiClient {
    func send(_ request: URLRequest, adapter: URLRequestAdapter?) -> Task<Response>
}

public class HttpClient: ApiClient {

    public static let `default`: HttpClient = HttpClient()

    public var requetAdapter: URLRequestAdapter?

    public var urlSession: URLSession = URLSession.shared

    public func send(_ request: URLRequest, adapter: URLRequestAdapter?) -> Task<Response> {
        let prepared = (adapter ?? requetAdapter)?.adapt(origin: request) ?? request
        let tcs = Task<Response>.Source()

        let dataTask = urlSession.dataTask(with: prepared) { (data, response, error) in
            try? tcs.complete(Response(request: prepared, content: data, response: response, error: error))
        }

        tcs.task.linked = dataTask

        dataTask.resume()

        return tcs.task
    }
}

extension URLSessionTask: Cancellable {}

extension Response: CustomDebugStringConvertible {

    public var debugDescription: String {
        if let response = response {
            return response.debugDescription
        } else if let error = error {
            return "Requset: \(request.debugDescription) failed with error: \(error)"
        } else {
            return "Incompleted: \(request.debugDescription)"
        }
    }
}
