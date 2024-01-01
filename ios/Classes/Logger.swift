/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 `Logger` handles logging of events during a CarPlay session.
 */

import Foundation
import os

/// Structure representing an event with a date and text.
struct Event: Hashable {
    let date: Date!
    let text: String!
}

/// Protocol defining the requirements for a logger.
protocol LoggerProtocol {
    /// Append a new event to the log. The system adds all events at the 0 index.
    func appendEvent(_: String)

    /// Fetch the list of events this logger received.
    var events: [Event] { get }
}

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// All logs related to tracking and analytics.
    static let statistics = Logger(subsystem: subsystem, category: "statistics")
}

/// Protocol defining the requirements for a logger delegate.
protocol LoggerDelegate: AnyObject {
    /// The logger has received a new event.
    func loggerDidAppendEvent()
}

/// Class implementing the LoggerProtocol for logging events in memory.
class MemoryLogger: LoggerProtocol {
    /// Shared instance of the MemoryLogger.
    static let shared = MemoryLogger()

    /// Weak reference to the logger delegate.
    weak var delegate: LoggerDelegate?

    /// Array to store logged events.
    public private(set) var events: [Event]

    /// Operation queue for logging events.
    private let loggingQueue: OperationQueue

    /// Private initializer to enforce singleton pattern.
    private init() {
        events = []
        loggingQueue = OperationQueue()
        loggingQueue.maxConcurrentOperationCount = 1
        loggingQueue.name = "Memory Logger Queue"
        loggingQueue.qualityOfService = .userInitiated
    }

    /// Appends a new event to the log.
    /// - Parameter event: The event text to be logged.
    func appendEvent(_ event: String) {
        loggingQueue.addOperation {
            self.events.insert(Event(date: Date(), text: event), at: 0)

            Logger.statistics.log("\(event)")

            guard let delegate = self.delegate else { return }

            DispatchQueue.main.async {
                delegate.loggerDidAppendEvent()
            }
        }
    }
}
