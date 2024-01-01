//
//  FCPStreamHandlerPlugin.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import Flutter

/// Flutter CarPlay (FCP) Stream Handler Plugin for handling communication between Flutter and CarPlay.
@available(iOS 14.0, *)
class FCPStreamHandlerPlugin: NSObject, FlutterStreamHandler {
    /// Static property to store the Flutter event sink for communication.
    private static var eventSink: FlutterEventSink?

    /// Initializes the FCPStreamHandlerPlugin with the provided Flutter plugin registrar.
    /// - Parameter registrar: The Flutter plugin registrar.
    public required init(registrar: FlutterPluginRegistrar) {
        super.init()
        let eventChannel = FlutterEventChannel(name: makeFCPChannelId(event: "/event"),
                                               binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(self)
    }

    /// Sets up the event sink when a listener is added.
    /// - Parameters:
    ///   - arguments: The arguments passed when a listener is added (unused).
    ///   - eventSink: The Flutter event sink for communication.
    /// - Returns: A FlutterError if there is an issue, otherwise nil.
    public func onListen(withArguments _: Any?,
                         eventSink: @escaping FlutterEventSink) -> FlutterError?
    {
        FCPStreamHandlerPlugin.eventSink = eventSink
        return nil
    }

    /// Sends a CarPlay connection change event to the Flutter side.
    /// - Parameter status: The status of the CarPlay connection.
    public func sendCarplayConnectionChangeEvent(status: String) {
        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onCarplayConnectionChange, data: ["status": status])
    }

    /// Sends a custom event to the Flutter side.
    /// - Parameters:
    ///   - type: The type of the event.
    ///   - data: The data associated with the event.
    public static func sendEvent(type: String, data: [String: Any]) {
        guard let eventSink = FCPStreamHandlerPlugin.eventSink else {
            return
        }

        eventSink([
            "type": type,
            "data": data,
        ] as [String: Any])
    }

    /// Removes the event sink when the listener is canceled.
    /// - Parameter arguments: The arguments passed when the listener is canceled (unused).
    /// - Returns: A FlutterError if there is an issue, otherwise nil.
    public func onCancel(withArguments _: Any?) -> FlutterError? {
        FCPStreamHandlerPlugin.eventSink = nil
        return nil
    }
}
