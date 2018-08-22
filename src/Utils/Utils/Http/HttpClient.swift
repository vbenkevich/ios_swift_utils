//
//  HttpClient.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

open class RequestResult {

    init(_ request: URLRequest) {
        self.request = request
    }

    open let request: URLRequest
    open var response: URLResponse?
    open var data: Data?
    open var error: Error?
}

public class HttpClient {

    public static let `default`: HttpClient = HttpClient()

    public func ruquest(_ request: URLRequest) -> Task<RequestResult> {
        let tcs = Task<RequestResult>.Source()
        let result = RequestResult(request)

        tcs.task.linked = URLSession.shared.dataTask(with: request) { (data, response, error) in
            result.data = data
            result.response = response
            result.error = error
            try? tcs.complete(result)
        }

        return tcs.task
    }
}

extension URLSessionTask: Cancellable {}
