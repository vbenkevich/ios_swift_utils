//
//  Created on 19/09/2018
//  Copyright © Vladimir Benkevich 2018
//

import XCTest
@testable import JetLib

class HttpMocksTests: XCTestCase {

    var session: HttpClient.URLSessionMockDecorator!
    var testUrl1 = URL(string: "http://a.b.c")!
    var testUrl2 = URL(string: "http://c.b.a")!
    var client: HttpClient!

    override func setUp() {
        super.setUp()
        session = HttpClient.URLSessionMockDecorator(origin: URLSession.shared)
        client = HttpClient()
        client.urlSession = session
    }
    
    override func tearDown() {
        super.tearDown()
        session.cleanResults()
    }

    func testMockRequestPredicateAlwaysTrue() {
        let expTrue = expectation(description: "test = true")

        session.setResult(HTTPURLResponse.success(testUrl1), data: nil, error: nil, for: WildCardPredicate.instance, lifetime: .oneRequest)
        try! client.get(testUrl1).notify { _ in expTrue.fulfill() }

        wait(expTrue)
        XCTAssertNotNil(session.lastMockTask)
    }


    func testMockRequestPredicateAlwaysFalse() {
        let expFalse = expectation(description: "test = false")

        session.setResult(HTTPURLResponse.success(testUrl1), data: nil, error: nil, for: NoOnePredicate.instance, lifetime: .oneRequest)
        try! client.get(testUrl1).notify { _ in expFalse.fulfill() }

        wait(expFalse)
        XCTAssertNotNil(session.lastTask)
        XCTAssertNil(session.lastMockTask)
    }

    func testMockRequestPredicateString() {
        XCTAssertTrue(".*".test(request: URLRequest(url: testUrl1)))
        XCTAssertTrue("c\\.b\\.a".test(request: URLRequest(url: testUrl2)))
        XCTAssertFalse("d".test(request: URLRequest(url: testUrl2)))
    }

    func testMockRequestPredicateUrl() {
        XCTAssertTrue(testUrl1.test(request: URLRequest(url: testUrl1)))
        XCTAssertFalse(testUrl2.test(request: URLRequest(url: testUrl1)))
        XCTAssertTrue(URL(string: "http://")!.test(request: URLRequest(url: testUrl1)))
        XCTAssertTrue(URL(string: "a.b")!.test(request: URLRequest(url: testUrl1)))
        XCTAssertFalse(URL(string: "a.b")!.test(request: URLRequest(url: testUrl2)))
    }

    func testSetResultOneRequest() {
        let exp = expectation(description: "exp")
        let response = HTTPURLResponse.success(testUrl1)
        let data = Data(base64Encoded: "data")!
        let error = TestError()
        session.setResult(response, data: data, error: error, for: WildCardPredicate.instance, lifetime: .oneRequest)

        try! client.get(testUrl1).notify {
            XCTAssertEqual($0.result?.response, response)
            XCTAssertEqual($0.result?.content, data)
            XCTAssertEqual($0.result?.error as? TestError, error)
            exp.fulfill()
        }

        XCTAssertNotNil(session.lastMockTask)

        wait(exp)
    }

    func testSetResultOneRequestOnlyOneTime() {
        let expectation1 = expectation(description: "exp1")
        let expectation2 = expectation(description: "exp2")

        session.setResult(HTTPURLResponse.success(testUrl1),
                          data: Data(base64Encoded: "data")!,
                          error: TestError(),
                          for: WildCardPredicate.instance,
                          lifetime: .oneRequest)

        try! client.get(testUrl1).notify { _ in
            expectation1.fulfill()
        }

        wait(expectation1)

        try! client.get(testUrl1).notify {
            XCTAssertNil($0.result?.response)
            XCTAssertNil($0.result?.content)
            XCTAssertNotNil($0.result?.error)
            expectation2.fulfill()
        }

        wait(expectation2)

        XCTAssertNotNil(session.lastTask)
        XCTAssertNil(session.lastMockTask)
    }

    func testSetResultSessionRequests() {
        let expectation1 = expectation(description: "exp1")
        let expectation2 = expectation(description: "exp2")
        let response = HTTPURLResponse.success(testUrl1)
        let data = Data(base64Encoded: "data")!
        let error = TestError()

        session.setResult(response, data: data, error: error, for: WildCardPredicate.instance, lifetime: .thisSession)

        try! client.get(testUrl1).notify {
            XCTAssertEqual($0.result?.response, response)
            XCTAssertEqual($0.result?.content, data)
            XCTAssertEqual($0.result?.error as? TestError, error)
            expectation1.fulfill()
        }

        wait(expectation1)

        try! client.get(testUrl1).notify {
            XCTAssertEqual($0.result?.response, response)
            XCTAssertEqual($0.result?.content, data)
            XCTAssertEqual($0.result?.error as? TestError, error)
            expectation2.fulfill()
        }

        wait(expectation2)

        XCTAssertNotNil(session.lastTask)
        XCTAssertNotNil(session.lastMockTask)
    }

    func testSetResultSessionRequestsOnlyOneSession() {
        let expectation1 = expectation(description: "exp1")
        let expectation2 = expectation(description: "exp2")
        let response = HTTPURLResponse.success(testUrl1)
        let data = Data(base64Encoded: "data")!
        let error = TestError()
        let anotherSession = HttpClient.URLSessionMockDecorator(origin: URLSession.shared)
        let anotherClient = HttpClient()
        anotherClient.urlSession = anotherSession

        session.setResult(response, data: data, error: error, for: WildCardPredicate.instance, lifetime: .thisSession)

        try! client.get(testUrl1).notify {
            XCTAssertEqual($0.result?.response, response)
            XCTAssertEqual($0.result?.content, data)
            XCTAssertEqual($0.result?.error as? TestError, error)
            expectation1.fulfill()
        }

        try! anotherClient.get(testUrl1).notify {
            XCTAssertNil($0.result?.response)
            XCTAssertNil($0.result?.content)
            XCTAssertNotNil($0.result?.error)
            expectation2.fulfill()
        }

        wait(expectation1, expectation2)

        XCTAssertNotNil(session.lastMockTask)
        XCTAssertNotNil(anotherSession.lastTask)
        XCTAssertNil(anotherSession.lastMockTask)
    }

    func testSetResultAllSessionRequests() {
        let expectation1 = expectation(description: "exp1")
        let expectation2 = expectation(description: "exp2")
        let response = HTTPURLResponse.success(testUrl1)
        let data = Data(base64Encoded: "data")!
        let error = TestError()
        let anotherSession = HttpClient.URLSessionMockDecorator(origin: URLSession.shared)
        let anotherClient = HttpClient()
        anotherClient.urlSession = anotherSession

        session.setResult(response, data: data, error: error, for: WildCardPredicate.instance, lifetime: .allSessions)

        try! client.get(testUrl1).notify {
            XCTAssertEqual($0.result?.response, response)
            XCTAssertEqual($0.result?.content, data)
            XCTAssertEqual($0.result?.error as? TestError, error)
            expectation1.fulfill()
        }

        try! anotherClient.get(testUrl1).notify {
            XCTAssertEqual($0.result?.response, response)
            XCTAssertEqual($0.result?.content, data)
            XCTAssertEqual($0.result?.error as? TestError, error)
            expectation2.fulfill()
        }

        wait(expectation1, expectation2)

        XCTAssertNotNil(session.lastMockTask)
        XCTAssertNotNil(anotherSession.lastMockTask)
    }

    private class WildCardPredicate: MockRequestPredicate {

        static var instance = WildCardPredicate()

        func test(request: URLRequest) -> Bool {
            return true
        }
    }

    private class NoOnePredicate: MockRequestPredicate {

        static var instance = NoOnePredicate()

        func test(request: URLRequest) -> Bool {
            return false
        }
    }
}
