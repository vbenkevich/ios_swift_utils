//
//  HTTPURLResponse.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

extension HTTPURLResponse {

    static func success(_ request: URLRequest) -> HTTPURLResponse {
        return HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.0", headerFields: request.allHTTPHeaderFields)!
    }

    static func success(_ requestUrl: URL) -> HTTPURLResponse {
        return HTTPURLResponse(url: requestUrl, statusCode: 200, httpVersion: "1.0", headerFields: [:])!
    }
}
