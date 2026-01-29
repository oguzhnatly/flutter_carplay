//
//  FCPSharedNowPlaying.swift
//  flutter_carplay
//
//  Created by Koen Van Looveren on 16/09/2022.
//

import CarPlay

@available(iOS 14.0, *)
class FCPSharedNowPlayingTemplate {
  private static var buttonInstances: [FCPNowPlayingButtonProtocol] = []
  
  var get: CPTemplate {
    return CPNowPlayingTemplate.shared
  }

  init() {}
  
  /// Sets custom buttons on the Now Playing template.
  /// - Parameter buttons: Array of button dictionaries from Flutter
  static func setButtons(_ buttons: [[String: Any]]) {
    // Create button instances
    buttonInstances = buttons.compactMap { FCPNowPlayingButtonFactory.createButton(from: $0) }
    
    // Get the native buttons
    let nowPlayingButtons = buttonInstances.map { $0.getButton() }
    
    // Update the shared Now Playing template
    CPNowPlayingTemplate.shared.updateNowPlayingButtons(nowPlayingButtons)
  }
}

@available(iOS 14.0, *)
extension FCPSharedNowPlayingTemplate: FCPRootTemplate {
     var elementId: String {
         return "FCPSharedNowPlayingTemplate"
     }
}
