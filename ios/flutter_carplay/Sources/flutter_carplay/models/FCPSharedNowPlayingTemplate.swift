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

@available(iOS 14.0, *)
protocol FCPNowPlayingButton {
  var get: CPNowPlayingButton { get }
}

@available(iOS 14.0, *)
class FCPNowPlayingImageButton: FCPNowPlayingButton {
  private(set) var elementId: String
  private var image: String
  private var isEnabled: Bool
  private var isSelected: Bool

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.image = obj["image"] as! String
    self.isEnabled = obj["isEnabled"] as? Bool ?? true
    self.isSelected = obj["isSelected"] as? Bool ?? false
  }

  var get: CPNowPlayingButton {
    let elementId = self.elementId
    let uiImage = UIImage(systemName: image) ?? makeUIImage(from: image.toImageSource())
    let button = CPNowPlayingImageButton(image: uiImage) { _ in
      FCPStreamHandlerPlugin.sendEvent(
        type: FCPChannelTypes.onNowPlayingButtonPressed, data: ["elementId": elementId])
    }
    button.isEnabled = isEnabled
    button.isSelected = isSelected
    return button
  }
}

@available(iOS 14.0, *)
class FCPNowPlayingPlaybackRateButton: FCPNowPlayingButton {
  private(set) var elementId: String
  private var isEnabled: Bool
  private var isSelected: Bool

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.isEnabled = obj["isEnabled"] as? Bool ?? true
    self.isSelected = obj["isSelected"] as? Bool ?? false
  }

  var get: CPNowPlayingButton {
    let elementId = self.elementId
    let button = CPNowPlayingPlaybackRateButton { _ in
      FCPStreamHandlerPlugin.sendEvent(
        type: FCPChannelTypes.onNowPlayingButtonPressed, data: ["elementId": elementId])
    }
    button.isEnabled = isEnabled
    button.isSelected = isSelected
    return button
  }
}

@available(iOS 14.0, *)
class FCPNowPlayingObserver: NSObject, CPNowPlayingTemplateObserver {
  static let shared = FCPNowPlayingObserver()

  func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
    FCPStreamHandlerPlugin.sendEvent(
      type: FCPChannelTypes.onNowPlayingUpNextButtonPressed, data: [:])
  }
}
