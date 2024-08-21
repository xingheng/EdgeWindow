//
//  Logger.swift
//  EdgeWindow
//
//  Created by WeiHan on 2024/8/9.
//

import Foundation

enum LogLevel: Int {
    case debug = 0
    case info
    case warning
    case error
}

class Logger {
    private static var logLevel: LogLevel = .debug

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    private(set) static var logFileURL: URL? = {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(Bundle.main.bundleIdentifier ?? "app").log")
    }()

    static func setLogLevel(_ level: LogLevel) {
        logLevel = level
    }

    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, file: file, function: function, line: line)
    }

    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }

    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, file: file, function: function, line: line)
    }

    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, file: file, function: function, line: line)
    }

    private static func log(_ level: LogLevel, _ message: String, file: String, function: String, line: Int) {
        guard level.rawValue >= logLevel.rawValue else { return }

        let fileName = (file as NSString).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())

        let logMessage = "[\(timestamp)] [\(level)] [\(fileName):\(line)] [\(function)] - \(message)"

        print(logMessage)

        // Append log message to the log file
        if let logFileURL = logFileURL {
            do {
                try logMessage.appendLineToURL(fileURL: logFileURL)
            } catch {
                print("Error writing to log file: \(error)")
            }
        }
    }
}

extension String {
    func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }

    func appendToURL(fileURL: URL) throws {
        let data = self.data(using: .utf8)!

        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        } else {
            try data.write(to: fileURL, options: .atomic)
        }
    }
}
