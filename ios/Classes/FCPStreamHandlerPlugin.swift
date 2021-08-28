//
//  FCPStreamHandlerPlugin.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import Flutter

@available(iOS 14.0, *)
class FCPStreamHandlerPlugin: NSObject, FlutterStreamHandler {
  private static var eventSink: FlutterEventSink?
  
  public required init(registrar: FlutterPluginRegistrar) {
    super.init()
    let eventChannel = FlutterEventChannel(name: makeFCPChannelId(event: "/event"),
                                           binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(self)
    return
  }
  
  public func onListen(withArguments arguments: Any?,
                       eventSink: @escaping FlutterEventSink) -> FlutterError? {
    FCPStreamHandlerPlugin.eventSink = eventSink
    return nil
  }
  
  public func sendCarplayConnectionChangeEvent(status: String) {
    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onCarplayConnectionChange, data: ["status": status])
  }
  
  public static func sendEvent(type: String, data: Dictionary<String, Any>) {
    guard let eventSink = FCPStreamHandlerPlugin.eventSink else {
      return
    }
    
    eventSink([
      "type": type,
      "data": data,
    ] as Dictionary<String, Any>)
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    FCPStreamHandlerPlugin.eventSink = nil
    return nil
  }
}

