//
//  Created on 28/08/2018
//  Copyright © Vladimir Benkevich 2018
//


import XCTest
@testable import Utils

class HttpClientBasicTests: XCTestCase {

    var client: HttpClient!
    var mockSession: HttpClient.URLSessionMockDecorator!
    var testRequest = URLRequest(url: URL(string: "http://apple.com")!)

    override func setUp() {
        super.setUp()
        client = HttpClient()
        mockSession = HttpClient.URLSessionMockDecorator(origin: client.urlSession)
        client.urlSession = mockSession
    }

    func testRequestExecution() {
        let callbackExp = expectation(description: "callback")

        let requestTask: Task<HttpResponse> = client.request(testRequest)
        requestTask.notify { _ in
            callbackExp.fulfill()
        }

        wait(for: [callbackExp], timeout: 1)
    }

    func testCallbackParams() {
        let callbackExp = expectation(description: "callback")

        let request = testRequest
        let response = HTTPURLResponse.success(request)
        let error = TestError()
        let data = "test content".data(using: .utf8)

        mockSession.setResult(response, data: data, error: error, for: ".", lifetime: .oneRequest)

        let requestTask: Task<HttpResponse> = client.request(request)
        requestTask.notify {
            XCTAssertEqual($0.result?.content, data)
            XCTAssertEqual($0.result?.request, request)
            XCTAssertEqual($0.result?.error as? TestError, error)

            callbackExp.fulfill()
        }

        wait(for: [callbackExp], timeout: 1)
    }

    func testRequestGlobalAdapter() {
        let adapter = TestRequestAdapter()
        client.requetAdapter = adapter

        let callbackExp = expectation(description: "callback")

        let requestTask: Task<HttpResponse> = client.request(testRequest)
        requestTask.notify {
            XCTAssertEqual($0.result?.request.allHTTPHeaderFields![adapter.headerField], adapter.headerValue)
            callbackExp.fulfill()
        }

        wait(for: [callbackExp], timeout: 1)
    }

    func testRequestLocalAdapter() {
        let adapter = TestRequestAdapter()
        let callbackExp = expectation(description: "callback")

        let requestTask: Task<HttpResponse> = client.request(testRequest, adapter: adapter)
        requestTask.notify {
            XCTAssertEqual($0.result?.request.allHTTPHeaderFields![adapter.headerField], adapter.headerValue)
            callbackExp.fulfill()
        }

        wait(for: [callbackExp], timeout: 1)
    }

    func testRequestAdapterPriority() {
        let globalAdapter = TestRequestAdapter()
        let localAdapter = TestRequestAdapter()
        let callbackExp = expectation(description: "callback")

        localAdapter.headerField = "local name"
        localAdapter.headerValue = "local value"
        client.requetAdapter = globalAdapter

        let requestTask: Task<HttpResponse> = client.request(testRequest, adapter: localAdapter)
        requestTask.notify {
            XCTAssertEqual($0.result?.request.allHTTPHeaderFields![localAdapter.headerField], localAdapter.headerValue)
            XCTAssertNil($0.result?.request.allHTTPHeaderFields![globalAdapter.headerField])
            callbackExp.fulfill()
        }

        wait(for: [callbackExp], timeout: 1)
    }

    func testCancelRequest() {
        let callbackExp = expectation(description: "callback")

        mockSession.delay = .seconds(2)
        mockSession.setResult(nil, for: testRequest.url!)

        let requestTask: Task<HttpResponse> = client.request(testRequest)
        requestTask.notify {
            XCTAssertEqual($0.status, .cancelled)
            callbackExp.fulfill()
        }

        try! requestTask.cancel()

        XCTAssertTrue(mockSession.lastMockTask!.canceled)

        wait(for: [callbackExp], timeout: 1)
    }

    class TestRequestAdapter: URLRequestAdapter {

        var headerValue = "field value"
        var headerField = "field name"

        func adapt(origin: URLRequest) -> URLRequest {
            var adapted = origin
            adapted.addValue(headerValue, forHTTPHeaderField: headerField)
            return adapted
        }
    }
}
