//
//  Created on 19/09/2018
//  Copyright © Vladimir Benkevich 2018
//

import Foundation

public extension HttpClient {

    public class URLSessionMockDecorator: URLSession {

        public typealias Callback = (Data?, URLResponse?, Error?) -> Swift.Void
        typealias Result = (predicate: MockRequestPredicate, response: URLResponse?, data: Data?, error: Error?)

        public enum Lifetime {
            case oneRequest
            case thisSession
            case allSessions
        }

        private let origin: URLSession

        public init(origin: URLSession) {
            self.origin = origin
        }

        public var delay: DispatchTimeInterval = .milliseconds(200)

        public var callbackQueue: DispatchQueue = DispatchQueue(label: "mock.session.callback")

        public private (set) var lastTask: URLSessionDataTask?

        public var lastMockTask: SessionTask? {
            return lastTask as? SessionTask
        }

        public func setResult(_ response: URLResponse?, data: Data? = nil, error: Error? = nil,
                              for predicate: MockRequestPredicate,
                              lifetime: Lifetime = .thisSession) {
            let result = Result(predicate: predicate, response: response, data: data, error: error)
            URLSessionMockDecorator.resultsQueue.sync {
                switch lifetime {
                case .oneRequest:   self.requestMocks.append(result)
                case .thisSession:  self.mocks.append(result)
                case .allSessions:  URLSessionMockDecorator.mocks.append(result)
                }
            }
        }

        public override func dataTask(with request: URLRequest, completionHandler: @escaping Callback) -> URLSessionDataTask {
            var task: URLSessionDataTask!

            if let result = getAcceptableResultSafe(for: request) {
                task = SessionTask(result, queue: callbackQueue, delay: delay, completionHandler: completionHandler)
            } else {
                task = origin.dataTask(with: request, completionHandler: completionHandler)
            }

            lastTask = task

            return task
        }

        private static let resultsQueue: DispatchQueue = DispatchQueue(label: "mock.session.result", qos: .default)
        private static var mocks = [Result]()
        private var mocks = [Result]()
        private var requestMocks = [Result]()

        private func getAcceptableResultSafe(for request: URLRequest) -> Result? {
            return URLSessionMockDecorator.resultsQueue.sync {
                return getResult(for: request, from: &self.requestMocks, shouldRemove: true)
                    ?? getResult(for: request, from: &self.mocks)
                    ?? getResult(for: request, from: &URLSessionMockDecorator.mocks)
            }
        }

        private func getResult(for request: URLRequest, from collection: inout [Result], shouldRemove: Bool = false) -> Result? {
            if !shouldRemove {
                return collection.first(where: {$0.predicate.test(request: request)})
            }

            if let node = collection.enumerated().first(where: {$0.element.predicate.test(request: request)}) {
                collection.remove(at: node.offset)
                return node.element
            } else {
                return nil
            }
        }

        public class SessionTask: URLSessionDataTask {

            let queue: DispatchQueue
            let delay: DispatchTimeInterval

            private var result: Result?
            private var completionHandler: Callback?

            init(_ result: Result, queue: DispatchQueue, delay: DispatchTimeInterval, completionHandler: @escaping Callback) {
                self.queue = queue
                self.delay = delay
                self.result = result
                self.completionHandler = completionHandler
            }

            public private (set) var canceled: Bool = false {
                didSet {
                    if canceled {
                        invokeCallbackIfNeeded()
                    }
                }
            }

            override public func cancel() {
                self.canceled = true
            }

            override public func resume() {
                guard !canceled else {
                    return
                }

                queue.asyncAfter(deadline: .now() + delay, execute: {
                    self.invokeCallbackIfNeeded()
                })
            }

            func invokeCallbackIfNeeded() {
                guard let result = result, let callback = completionHandler else {
                    return
                }

                self.completionHandler = nil
                self.result = nil

                callback(result.data, result.response, result.error)
            }
        }
    }
}

public protocol MockRequestPredicate {

    func test(request: URLRequest) -> Bool
}

extension String: MockRequestPredicate {

    public func test(request: URLRequest) -> Bool {
        let regex = try? NSRegularExpression(pattern: self)
        let requestString = request.url?.absoluteString ?? ""
        return regex?.matches(in: requestString, options: [], range: NSRange(location: 0, length: requestString.count)).isEmpty == false
    }
}

extension URL: MockRequestPredicate {

    public func test(request: URLRequest) -> Bool {
        return request.url?.absoluteString.contains(self.absoluteString) == true
    }
}
