//
//  Created on 27/08/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public extension HttpClient {

    public class Json {
        public static var defaultDecoder: JSONDecoder = JSONDecoder()
        public static var defaultEncoder: JSONEncoder = JSONEncoder()
    }

    public func request<TBody: Encodable, TResponse: HttpResponse>(_ url: URL, jsonBody: TBody, method: String = HttpMethod.post, encoder: JSONEncoder? = nil, adapter: URLRequestAdapter?) throws -> Task<TResponse> {
        let encoder = encoder ?? HttpClient.Json.defaultEncoder
        let encodedData = try encoder.encode(jsonBody)

        return try self.request(url, body: encodedData, method: method, adapter: adapter)
    }

    public func post<TBody: Encodable, TResponse: HttpResponse>(_ url: URL, jsonBody: TBody, encoder: JSONEncoder? = nil, adapter: URLRequestAdapter? = nil) throws -> Task<TResponse> {
        return try self.request(url, jsonBody: jsonBody, method: HttpMethod.post, encoder: encoder, adapter: adapter)
    }

    public func put<TBody: Encodable, TResponse: HttpResponse>(_ url: URL, jsonBody: TBody, encoder: JSONEncoder? = nil, adapter: URLRequestAdapter? = nil) throws -> Task<TResponse> {
        return try self.request(url, jsonBody: jsonBody, method: HttpMethod.put, encoder: encoder, adapter: adapter)
    }
}

open class JsonResponse<T: Decodable>: HttpResponse {

    open var decoder: JSONDecoder?

    public private (set) var data: T?

    var currentDecoder: JSONDecoder {
        return decoder ?? HttpClient.Json.defaultDecoder
    }

    open override func process(content: Data?, response: URLResponse?, originError: Error?) throws {
        if let content = content {
            data = try currentDecoder.decode(T.self, from: content)
        }
    }
}
