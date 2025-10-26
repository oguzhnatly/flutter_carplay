//
//  FCPSharedNowPlaying.swift
//  flutter_carplay
//
//  Created by Koen Van Looveren on 16/09/2022.
//

import CarPlay

@available(iOS 14.0, *)
class FCPSharedNowPlayingTemplate {
  var get: CPTemplate {
    return CPNowPlayingTemplate.shared
  }

  init() {}
}

@available(iOS 14.0, *)
extension FCPSharedNowPlayingTemplate: FCPRootTemplate {
     var elementId: String {
         return "FCPSharedNowPlayingTemplate"
     }
}
