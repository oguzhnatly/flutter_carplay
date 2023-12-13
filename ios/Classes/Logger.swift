/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`Logger` handles logging of events during a CarPlay session.
*/

import Foundation
import os

struct Event: Hashable {
    let date: Date!
    let text: String!
}

/**
 `Logger` describes an object that can receive interesting events from elsewhere in the app
 and persist them to memory, disk, a network connection, or elsewhere.
 */
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

/**
Coastal Roads informs `LoggerDelegate` of logging events.
 */
protocol LoggerDelegate: AnyObject {
    
    /// The logger has received a new event.
    func loggerDidAppendEvent()
}

/**
 `MemoryLogger` is a type of `Logger` that records events in memory about the life cycle of the app.
 */
class MemoryLogger: LoggerProtocol {
    
    static let shared = MemoryLogger()
        
    weak var delegate: LoggerDelegate?
    
    public private(set) var events: [Event]
    
    private let loggingQueue: OperationQueue
    
    private init() {
        events = []
        loggingQueue = OperationQueue()
        loggingQueue.maxConcurrentOperationCount = 1
        loggingQueue.name = "Memory Logger Queue"
        loggingQueue.qualityOfService = .userInitiated
    }
    
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
