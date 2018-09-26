//
//  Created on 28/08/2018
//  Copyright © Vladimir Benkevich 2018
//


import XCTest
@testable import Utils

class HttpClientHelpersTests: XCTestCase {
    
    var client: HttpClient!
    var session: HttpClient.URLSessionMockDecorator!
    var testUrl = URL(string: "http://apple.com")!

    override func setUp() {
        super.setUp()
        client = HttpClient()
        session = HttpClient.URLSessionMockDecorator(origin: client.urlSession)
        client.urlSession = session
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testRequestBuilding() {
        let data = "test budy".data(using: .utf8)
        let testMethod = "TEST"
        let requestAdapted = expectation(description: "adapted")

        let adapter = AssertRequestAdapter {
            XCTAssertEqual($0.httpBody, data)
            XCTAssertEqual($0.url, self.testUrl)
            XCTAssertEqual($0.httpMethod, testMethod)
            requestAdapted.fulfill()
        }

        XCTAssertNoThrow(try _ = client.request(testUrl, body: data, method: testMethod, adapter: adapter))
        wait(for: [requestAdapted], timeout: 1)
    }

    func testPostRequestBuilding() {
        let data = "test post content".data(using: .utf8)!
        let requestAdapted = expectation(description: "adapted")

        let adapter = AssertRequestAdapter {
            XCTAssertEqual($0.httpBody, data)
            XCTAssertEqual($0.url, self.testUrl)
            XCTAssertEqual($0.httpMethod, HttpMethod.post)
            requestAdapted.fulfill()
        }

        XCTAssertNoThrow(try _ = client.post(testUrl, body: data, adapter: adapter))
        wait(for: [requestAdapted], timeout: 1)
    }

    func testPutRequestBuilding() {
        let data = "test put content".data(using: .utf8)!
        let requestAdapted = expectation(description: "adapted")

        let adapter = AssertRequestAdapter {
            XCTAssertEqual($0.httpBody, data)
            XCTAssertEqual($0.url, self.testUrl)
            XCTAssertEqual($0.httpMethod, HttpMethod.put)
            requestAdapted.fulfill()
        }

        XCTAssertNoThrow(try _ = client.put(testUrl, body: data, adapter: adapter))
        wait(for: [requestAdapted], timeout: 1)
    }

    func testGetRequestBuilding() {
        let requestAdapted = expectation(description: "adapted")
        let params: [String : CustomStringConvertible] = [
            ">> &?! =\"\'\n\t\r%09<<"  : ">> &?! =\"\'\n\t\r%20<<",
            "param1"                : false,
            "param2"                : 10.2,
            "param3"                : "value"
        ]

        let url = URL(string: "http://apple.com?%3E%3E%20%26?!%20%3D%22'%0A%09%0D%2509%3C%3C=%3E%3E%20%26?!%20%3D%22'%0A%09%0D%2520%3C%3C&param1=false&param3=value&param2=10.2")

        let adapter = AssertRequestAdapter {
            XCTAssertNil($0.httpBody)
            XCTAssertEqual($0.httpMethod, HttpMethod.get)
            XCTAssertEqual($0.url, url)

            requestAdapted.fulfill()
        }

        XCTAssertNoThrow(try _ = client.get(testUrl, params: params, adapter: adapter))
        wait(for: [requestAdapted], timeout: 1)
    }

    func testValidJsonResponse() {
        let callbackExp = expectation(description: "callback")
        let data = TestData(val1: UUID().uuidString)

        session.setResult(HTTPURLResponse.success(testUrl), data: try! JSONEncoder().encode(data), error: nil, for: testUrl, lifetime: .allSessions)

        let responseTask: Task<JsonResponse<TestData>> = client.request(URLRequest(url: testUrl))
        responseTask.notify {
            XCTAssertEqual($0.result?.data, data)
            XCTAssertNil($0.result?.error)
            callbackExp.fulfill()
        }

        wait(for: [callbackExp], timeout: 1)
    }

    func testInvalidJsonResponse() {
        let callbackExp = expectation(description: "callback")
        let data = TestData2(val2: UUID().uuidString)

        session.setResult(HTTPURLResponse.success(testUrl), data: try! JSONEncoder().encode(data), error: nil, for: testUrl)

        let responseTask: Task<JsonResponse<TestData>> = client.request(URLRequest(url: testUrl))
        responseTask.notify {
            XCTAssertNotNil($0.result?.error as? DecodingError)
            XCTAssertNil($0.result?.data)
            callbackExp.fulfill()
        }

        wait(for: [callbackExp], timeout: 1)
    }

    func testPostJsonBody() {
        let body = TestData(val1: "body")
        let bodyData = try! JSONEncoder().encode(body)
        let requestAdapted = expectation(description: "adapted")

        let adapter = AssertRequestAdapter {
            XCTAssertEqual($0.httpBody, bodyData)
            XCTAssertEqual($0.url, self.testUrl)
            XCTAssertEqual($0.httpMethod, HttpMethod.post)
            requestAdapted.fulfill()
        }

        XCTAssertNoThrow(try _ = client.post(testUrl, jsonBody: body, adapter: adapter))
        wait(for: [requestAdapted], timeout: 1)
    }

    func testPutJsonBody() {
        let body = TestData(val1: "body")
        let bodyData = try! JSONEncoder().encode(body)
        let requestAdapted = expectation(description: "adapted")

        let adapter = AssertRequestAdapter {
            XCTAssertEqual($0.httpBody, bodyData)
            XCTAssertEqual($0.url, self.testUrl)
            XCTAssertEqual($0.httpMethod, HttpMethod.put)
            requestAdapted.fulfill()
        }

        XCTAssertNoThrow(try _ = client.put(testUrl, jsonBody: body, adapter: adapter))
        wait(for: [requestAdapted], timeout: 1)
    }

    /// MARK coverage ;)

    func testErrorInit() {
        let descr = "O.o"
        let error = HttpError(descr)
        XCTAssertEqual(error.description, descr)
    }

    func testSuccessCodes() {
        let wrongTypeResponse = URLResponse(url: testUrl, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        XCTAssertThrowsError(try wrongTypeResponse.checkHttpSuccess())

        XCTAssertFalse(try! HTTPURLResponse(url: testUrl, statusCode: 199, httpVersion: nil, headerFields: nil)!.checkHttpSuccess())
        XCTAssertTrue(try! HTTPURLResponse(url: testUrl, statusCode: 200, httpVersion: nil, headerFields: nil)!.checkHttpSuccess())
        XCTAssertTrue(try! HTTPURLResponse(url: testUrl, statusCode: 250, httpVersion: nil, headerFields: nil)!.checkHttpSuccess())
        XCTAssertTrue(try! HTTPURLResponse(url: testUrl, statusCode: 299, httpVersion: nil, headerFields: nil)!.checkHttpSuccess())
        XCTAssertFalse(try! HTTPURLResponse(url: testUrl, statusCode: 300, httpVersion: nil, headerFields: nil)!.checkHttpSuccess())
        XCTAssertFalse(try! HTTPURLResponse(url: testUrl, statusCode: 400, httpVersion: nil, headerFields: nil)!.checkHttpSuccess())
        XCTAssertFalse(try! HTTPURLResponse(url: testUrl, statusCode: 500, httpVersion: nil, headerFields: nil)!.checkHttpSuccess())
    }

    struct TestData: Codable, Equatable {
        let val1: String
    }

    struct TestData2: Codable, Equatable {
        let val2: String
    }

    class AssertRequestAdapter: URLRequestAdapter {

        var assert: (URLRequest) throws -> Void

        init(assert: @escaping (URLRequest) throws -> Void) {
            self.assert = assert
        }

        func adapt(origin: URLRequest) -> URLRequest {
            XCTAssertNoThrow(try assert(origin))
            return origin
        }
    }
}
