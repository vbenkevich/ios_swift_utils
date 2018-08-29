//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol URLRequestAdapter {

    func adapt(origin: URLRequest) -> URLRequest
}

public class HttpClient {

    public static let `default`: HttpClient = HttpClient()

    public var requetAdapter: URLRequestAdapter?

    public var urlSession: URLSession = URLSession.shared

    public func request<TResponse: HttpResponse>(_ request: URLRequest, adapter: URLRequestAdapter? = nil) -> Task<TResponse> {
        let prepared = (adapter ?? requetAdapter)?.adapt(origin: request) ?? request
        let tcs = Task<TResponse>.Source()
        let result = TResponse(prepared)

        let dataTask = urlSession.dataTask(with: prepared) { (data, response, error) in
            // order is important
            result.origin = response
            result.error = error
            result.content = data
            try? tcs.complete(result)
        }

        tcs.task.linked = dataTask

        dataTask.resume()

        return tcs.task
    }
}

extension URLSessionTask: Cancellable {}
