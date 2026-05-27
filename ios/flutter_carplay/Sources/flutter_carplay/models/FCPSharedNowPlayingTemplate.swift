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

  public func update(with: any FCPTemplate) {
    guard let with = with as? FCPSharedNowPlayingTemplate else {
      return
    }
  }
}

@available(iOS 14.0, *)
extension FCPSharedNowPlayingTemplate: FCPTemplate {
  var elementId: String {
    return "FCPSharedNowPlayingTemplate"
  }
}
