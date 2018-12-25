//
//  Created on 22/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public class HttpMethod {

    public static let get     = "GET"
    public static let post    = "POST"
    public static let put     = "PUT"
    public static let delete  = "DELETE"
}

public extension HttpClient {

    public func request(url: URL, urlParams: [String: CustomStringConvertible]?, body: Data?, method: String, adapter: URLRequestAdapter?) throws -> Task<Response> {
        guard let originUrlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw HttpException.badUrlFormat
        }

        var components = originUrlComponents

        if let params = urlParams {
            components.queryItems = params.map {
                URLQueryItem(name: $0.0, value: $0.1.description)
            }
        }

        guard let resultUrl = components.url else {
            throw HttpException.badParametersFormat
        }

        var request = URLRequest(url: resultUrl)
        request.httpMethod = method
        request.httpBody = body

        return self.send(request, adapter: adapter)
    }

    public func get(_ url: URL, id: CustomStringConvertible? = nil, urlParams: [String: CustomStringConvertible]? = nil, adapter: URLRequestAdapter? = nil) throws -> Task<Response> {
        var resultUrl = url

        if let id = id {
            resultUrl = resultUrl.appendingPathComponent(id.description)
        }

        return try request(url: resultUrl, urlParams: urlParams, body: nil, method: HttpMethod.get, adapter: adapter)
    }

    public func post(_ url: URL, body: Data, adapter: URLRequestAdapter? = nil) throws -> Task<Response> {
        return try request(url: url, urlParams: nil, body: body, method: HttpMethod.post, adapter: adapter)
    }

    public func put(_ url: URL, body: Data, adapter: URLRequestAdapter? = nil) throws -> Task<Response> {
        return try request(url: url, urlParams: nil, body: body, method: HttpMethod.put, adapter: adapter)
    }

    public func delete(_ url: URL, id: CustomStringConvertible, adapter: URLRequestAdapter? = nil) throws -> Task<Response> {
        return try request(url: url.appendingPathComponent(id.description), urlParams: nil, body: nil, method: HttpMethod.delete, adapter: adapter)
    }
}
