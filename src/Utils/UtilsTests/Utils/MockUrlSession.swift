//
//  MockUrlSession.swift
//
//  Created by Vladimir Benkevich
//  Copyright © 2018
//

import Foundation

class MockUrlSession: URLSession {

    var nextResult: Result = Result()

    var callbackQueue: DispatchQueue = DispatchQueue(label: "mock.urlSession.callback")
    var requestTime: DispatchTimeInterval = .milliseconds(1)
    var semaphore = DispatchSemaphore(value: 0)

    var lastTask: SessionTask?

    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
        let task = SessionTask(self)
        nextResult.completionHandler = completionHandler
        lastTask = task
        return task
    }

    func setNext(response: URLResponse? = nil, data: Data? = nil, error: Error? = nil) {
        nextResult.response = response
        nextResult.data = data
        nextResult.error = error
    }

    func pause() {
        nextResult.semaphore = semaphore
    }

    func resume() {
        semaphore.signal()
    }

    fileprivate func executeRequest() -> Result {
        defer {
            nextResult = Result()
        }
        return nextResult
    }

    class SessionTask: URLSessionDataTask {

        unowned var session: MockUrlSession

        var canceled = false
        var resumed = false

        init(_ session: MockUrlSession) {
            self.session = session
        }

        override func resume() {
            resumed = true

            let result = session.executeRequest()

            session.callbackQueue.asyncAfter(deadline: .now() + session.requestTime) {
                if let semaphore = result.semaphore {
                    semaphore.wait()
                }

                result.completionHandler(result.data, result.response, result.error)
            }
        }

        override func cancel() {
            canceled = true
        }
    }

    struct Result {

        init() {}

        var error: Error?
        var response: URLResponse?
        var data: Data?
        var semaphore: DispatchSemaphore?
        var completionHandler: ((Data?, URLResponse?, Error?) -> Swift.Void)!
    }
}
