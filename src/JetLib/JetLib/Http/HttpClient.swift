//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol URLRequestAdapter {

    func adapt(origin: URLRequest) -> URLRequest
}

public struct Response {
    let request: URLRequest
    let content: Data?
    let response: URLResponse?
    let error: Error?
}

public class HttpClient {

    public static let `default`: HttpClient = HttpClient()

    public var requetAdapter: URLRequestAdapter?

    public var urlSession: URLSession = URLSession.shared

    public func send(_ request: URLRequest, adapter: URLRequestAdapter? = nil) -> Task<Response> {
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
