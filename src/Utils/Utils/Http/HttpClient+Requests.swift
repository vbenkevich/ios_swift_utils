//
//  HttpClient+Requests.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

public class HttpMethod {

    public static let get     = "GET"
    public static let post    = "POST"
    public static let put     = "PUT"
    public static let delete  = "DELETE"
}

public extension HttpClient {

    public func request<TResponse: HttpResponse>(_ url: URL, body: Data?, method: String, adapter: URLRequestAdapter?) throws -> Task<TResponse> {
        guard URLComponents(url: url, resolvingAgainstBaseURL: true) != nil else {
            throw HttpError.badUrlFormat
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        return self.request(request, adapter: adapter)
    }

    public func get<TResponse: HttpResponse>(_ url: URL, params: [String: CustomStringConvertible] = [:], adapter: URLRequestAdapter? = nil) throws -> Task<TResponse> {
        guard let old = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw HttpError.badUrlFormat
        }

        var components = old
        components.queryItems = params.map {
            URLQueryItem(name: $0.0, value: $0.1.description)
        }

        guard let url = components.url else {
            throw HttpError.badParametersFormat
        }

        return try self.request(url, body: nil, method: HttpMethod.get, adapter: adapter)
    }

    public func post<TResponse: HttpResponse>(_ url: URL, body: Data, adapter: URLRequestAdapter? = nil) throws -> Task<TResponse> {
        return try request(url, body: body, method: HttpMethod.post, adapter: adapter)
    }

    public func put<TResponse: HttpResponse>(_ url: URL, body: Data, adapter: URLRequestAdapter? = nil) throws -> Task<TResponse> {
        return try request(url, body: body, method: HttpMethod.put, adapter: adapter)
    }
}
