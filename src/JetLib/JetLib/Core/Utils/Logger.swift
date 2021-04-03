//
//  Created on 09/01/2019
//  Copyright © Vladimir Benkevich 2019
//

import Foundation

public protocol LoggerOutput {

    func write(_ message: String, at logLevel: Logger.LogLevel)
}

open class Logger {

    public struct LogLevel: Equatable, Hashable {
        public let prefix: String

        public init(prefix: String) {
            self.prefix = prefix
        }
    }

    public static var outputs: [LoggerOutput] = [ConsoleOutput()]

    #if DEBUG
    public static var levels: Set<LogLevel> = Set([LogLevel.debug, LogLevel.info, LogLevel.error])
    #else
    public static var levels: Set<LogLevel> = Set([LogLevel.info, LogLevel.error])
    #endif

    public static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        return formatter
    }()

    public static func log(_ data: @autoclosure () throws -> Any?, at level: LogLevel) {
        guard levels.contains(level), !outputs.isEmpty else {
            return
        }

        do {
            let evaluated = try data()
            if let notNil = evaluated {
                write(message: String(describing: notNil), level: level)
            } else {
                write(message: "nil", level: level)
            }
        } catch {
            write(message: error.localizedDescription, level: .error)
        }
    }

    static func write(message: String, level: LogLevel) {
        let msg = "\(timeFormatter.string(from: Date()))\t\(level.prefix): \(message)"

        for output in outputs {
            output.write(msg, at: level)
        }
    }

    open class ConsoleOutput: LoggerOutput {

        open func write(_ message: String, at logLevel: Logger.LogLevel) {
            print(message)
        }
    }
}

public extension Logger.LogLevel {

    static let debug = Logger.LogLevel(prefix: "DEBUG")

    static let info = Logger.LogLevel(prefix: "INFO")

    static let error = Logger.LogLevel(prefix: "ERROR")
}

public extension Logger {

    static func debug(_ data: @autoclosure () throws -> Any?) {
        log(try data(), at: .debug)
    }

    static func info(_ data: @autoclosure () throws -> Any?) {
        log(try data(), at: .info)
    }

    static func error(_ error: Error) {
        log(error, at: .error)
    }

    static func error(_ data: @autoclosure () throws -> Any?) {
        log(try data(), at: .error)
    }
}
