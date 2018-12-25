//
//  Created on 25/12/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public protocol HttpResponseBodyDecoder {

    func decode<T: Decodable>(response: Response) throws -> T
}

public protocol HttpResponseErrorDecoder {

    func throwError(from response: Response) throws
}

public extension HttpClient {

    public enum Decoding {
        public static var defaultBodyDecoder: HttpResponseBodyDecoder = JsonBodyDecoder()
        public static var defaultErrorDecoder: HttpResponseErrorDecoder = DefaultErrorDecoder()
    }
}

public extension Task where T == Response {

    func decode<TData: Decodable>(_ bodyDecoder: HttpResponseBodyDecoder? = nil, _ errorDecoder: HttpResponseErrorDecoder? = nil) -> Task<TData> {
        let bodyDecoder = bodyDecoder ?? HttpClient.Decoding.defaultBodyDecoder
        let errorDecoder = errorDecoder ?? HttpClient.Decoding.defaultErrorDecoder

        return map {
            try errorDecoder.throwError(from: $0)
            return try bodyDecoder.decode(response: $0)
        }
    }
}

extension HttpClient {

    public enum Json {
        public static var defaultDecoder: JSONDecoder = JSONDecoder()
        public static var defaultEncoder: JSONEncoder = JSONEncoder()
    }

    public func request<TBody: Encodable>(url: URL,
                                          urlParams: [String: CustomStringConvertible]?,
                                          jsonBody: TBody,
                                          method: String = HttpMethod.post,
                                          encoder: JSONEncoder? = nil,
                                          adapter: URLRequestAdapter?) throws -> Task<Response> {

        let encoder = encoder ?? HttpClient.Json.defaultEncoder
        let encodedData = try encoder.encode(jsonBody)

        return try request(url: url, urlParams: urlParams, body: encodedData, method: method, adapter: adapter)
    }

    public func post<TBody: Encodable>(_ url: URL, jsonBody: TBody, encoder: JSONEncoder? = nil, adapter: URLRequestAdapter? = nil) throws -> Task<Response> {
        return try self.request(url: url, urlParams: nil, jsonBody: jsonBody, method: HttpMethod.post, encoder: encoder, adapter: adapter)
    }

    public func put<TBody: Encodable>(_ url: URL, jsonBody: TBody, encoder: JSONEncoder? = nil, adapter: URLRequestAdapter? = nil) throws -> Task<Response> {
        return try self.request(url: url, urlParams: nil, jsonBody: jsonBody, method: HttpMethod.put, encoder: encoder, adapter: adapter)
    }

    public class JsonBodyDecoder: HttpResponseBodyDecoder {

        public var decoder: JSONDecoder?

        private var currentDecoder: JSONDecoder {
            return decoder ?? HttpClient.Json.defaultDecoder
        }

        public func decode<T: Decodable>(response: Response) throws -> T {
            guard let body = response.content else {
                throw HttpException.responseEmptyBody
            }
            return try currentDecoder.decode(T.self, from: body)
        }
    }
}
