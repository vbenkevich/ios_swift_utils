//
//  HttpClient.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

public protocol URLRequestAdapter {

    func adapt(origin: URLRequest) -> URLRequest
}

public class HttpClient {

    public static let `default`: HttpClient = HttpClient()

    public var requetAdapter: URLRequestAdapter?

    public var urlSession: URLSession = URLSession.shared

    public func request(_ request: URLRequest, adapter: URLRequestAdapter? = nil) -> Task<HttpResponse> {
        let task: Task<HttpResponse> = self.request(request)
        return task
    }

    public func request<TResponse: HttpResponse>(_ request: URLRequest, adapter: URLRequestAdapter?) -> Task<TResponse> {
        let prepared = (adapter ?? requetAdapter)?.adapt(origin: request) ?? request
        let tcs = Task<TResponse>.Source()
        let result = TResponse(prepared)

        tcs.task.linked = URLSession.shared.dataTask(with: prepared) { (data, response, error) in
            // order is important
            result.origin = response
            result.error = error
            result.data = data
            try? tcs.complete(result)
        }

        return tcs.task
    }
}

extension URLSessionTask: Cancellable {}
