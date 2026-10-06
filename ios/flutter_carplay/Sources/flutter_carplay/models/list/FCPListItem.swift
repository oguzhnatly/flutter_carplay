//
//  FCPListItem.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import Flutter

@available(iOS 14.0, *)
final class FCPListItem {
  private(set) var _super: CPListItem?
  private(set) var elementId: String
  private(set) var text: String?
  private var detailText: String?
  private var isOnPressListenerActive: Bool = false
  private var completeHandler: (() -> Void)?
  private var image: String?
  private var imageData: FlutterStandardTypedData?
  private var imageTint: FCPImageTint?
  private var imageSize: FCPImageSize
  private var accessoryImage: String?
  private var trailingImage: String?
  private var trailingImageData: FlutterStandardTypedData?
  private var trailingImageTint: FCPImageTint?
  private var trailingImageSize: FCPImageSize
  private var playbackProgress: CGFloat?
  private var isPlaying: Bool?
  private var playingIndicatorLocation: CPListItemPlayingIndicatorLocation?
  private var accessoryType: CPListItemAccessoryType?

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.text = obj["text"] as? String
    self.detailText = obj["detailText"] as? String
    self.isOnPressListenerActive = obj["onPress"] as? Bool ?? false
    self.image = obj["image"] as? String
    self.imageData = obj["imageData"] as? FlutterStandardTypedData
    self.imageTint = FCPImageTint(from: obj["imageTint"] as? [String: Any])
    self.imageSize = FCPImageSize(from: obj["imageSize"] as? [String: Any])
    self.accessoryImage = obj["accessoryImage"] as? String
    self.trailingImage = obj["trailingImage"] as? String
    self.trailingImageData = obj["trailingImageData"] as? FlutterStandardTypedData
    self.trailingImageTint = FCPImageTint(from: obj["trailingImageTint"] as? [String: Any])
    self.trailingImageSize = FCPImageSize(from: obj["trailingImageSize"] as? [String: Any])
    self.playbackProgress = obj["playbackProgress"] as? CGFloat
    self.isPlaying = obj["isPlaying"] as? Bool
    self.setPlayingIndicatorLocation(fromString: obj["playingIndicatorLocation"] as? String)
    self.setAccessoryType(fromString: obj["accessoryType"] as? String)
  }

  private func handler(selectedItem: CPSelectableListItem, complete: @escaping () -> Void) {
    if isOnPressListenerActive {
      completeHandler = complete

      DispatchQueue.main.async {
        FCPStreamHandlerPlugin.sendEvent(
          type: FCPChannelTypes.onListItemSelected,
          data: ["elementId": self.elementId]
        )
      }
    } else {
      complete()
    }
  }

  var get: CPListTemplateItem {
    let listItem = CPListItem.init(text: text, detailText: detailText)
    listItem.handler = self.handler
    if image != nil {
      let slot = FCPImageSlot.listItem(imageSize)
      listItem.setImage(makeSafeUIPlaceholder(slot: slot))
      loadUIImage(from: image!, bytes: imageData, slot: slot, tint: imageTint) { uiImage in
        listItem.setImage(uiImage)
      }
    }

    let accessorySource = trailingImage ?? accessoryImage
    if accessorySource != nil {
      let slot = FCPImageSlot.listItem(trailingImageSize)
      listItem.setAccessoryImage(makeSafeUIPlaceholder(slot: slot))
      loadUIImage(
        from: accessorySource!, bytes: trailingImageData, slot: slot, tint: trailingImageTint
      ) { uiImage in
        listItem.setAccessoryImage(uiImage)
      }
    }

    if playbackProgress != nil {
      listItem.playbackProgress = playbackProgress!
    }
    if isPlaying != nil {
      listItem.isPlaying = isPlaying!
    }
    if playingIndicatorLocation != nil {
      listItem.playingIndicatorLocation = playingIndicatorLocation!
    }
    if accessoryType != nil && accessorySource == nil {
      listItem.accessoryType = accessoryType!
    }
    self._super = listItem
    return listItem
  }

  public func stopHandler() {
    guard self.completeHandler != nil else {
      return
    }
    self.completeHandler!()
    self.completeHandler = nil
  }

  public func update(args: [String: Any]) {
    let text = args["text"] as? String
    let detailText = args["detailText"] as? String
    let image = args["image"] as? String
    let imageData = args["imageData"] as? FlutterStandardTypedData
    let imageTint = FCPImageTint(from: args["imageTint"] as? [String: Any])
    let imageSize = FCPImageSize(from: args["imageSize"] as? [String: Any])
    let accessoryImage = args["accessoryImage"] as? String
    let trailingImage = args["trailingImage"] as? String
    let trailingImageData = args["trailingImageData"] as? FlutterStandardTypedData
    let trailingImageTint = FCPImageTint(from: args["trailingImageTint"] as? [String: Any])
    let trailingImageSize = FCPImageSize(from: args["trailingImageSize"] as? [String: Any])
    let playbackProgress = args["playbackProgress"] as? CGFloat
    let isPlaying = args["isPlaying"] as? Bool
    let playingIndicatorLocation = args["playingIndicatorLocation"] as? String
    let accessoryType = args["accessoryType"] as? String

    if text != nil {
      self._super?.setText(text!)
      self.text = text!
    }
    if detailText != nil {
      self._super?.setDetailText(detailText)
      self.detailText = detailText
    }

    let imageTintChanged = imageTint != self.imageTint
    let imageSizeChanged = imageSize.fraction != self.imageSize.fraction
    if let image = image, image != self.image || imageTintChanged || imageSizeChanged {
      let slot = FCPImageSlot.listItem(imageSize)
      self._super?.setImage(makeSafeUIPlaceholder(slot: slot))
      loadUIImage(from: image, bytes: imageData, slot: slot, tint: imageTint) { uiImage in
        self._super?.setImage(uiImage)
      }
      self.image = image
      self.imageData = imageData
      self.imageTint = imageTint
      self.imageSize = imageSize
    } else if image == nil && args.keys.contains("image") {
      self.image = nil
      self.imageData = nil
      self.imageTint = nil
      self._super?.setImage(nil)
    }

    let requestedAccessoryImage = trailingImage ?? accessoryImage
    let currentAccessoryImage = self.trailingImage ?? self.accessoryImage
    let trailingImageTintChanged = trailingImageTint != self.trailingImageTint
    let trailingImageSizeChanged = trailingImageSize.fraction != self.trailingImageSize.fraction
    if let requestedAccessoryImage = requestedAccessoryImage,
      requestedAccessoryImage != currentAccessoryImage || trailingImageTintChanged
        || trailingImageSizeChanged
    {
      let slot = FCPImageSlot.listItem(trailingImageSize)
      self._super?.setAccessoryImage(makeSafeUIPlaceholder(slot: slot))
      loadUIImage(
        from: requestedAccessoryImage,
        bytes: trailingImageData,
        slot: slot,
        tint: trailingImageTint
      ) { uiImage in
        self._super?.setAccessoryImage(uiImage)
      }
      self.accessoryImage = accessoryImage
      self.trailingImage = trailingImage
      self.trailingImageData = trailingImageData
      self.trailingImageTint = trailingImageTint
      self.trailingImageSize = trailingImageSize
    } else if requestedAccessoryImage == nil
      && (args.keys.contains("accessoryImage") || args.keys.contains("trailingImage"))
    {
      self.accessoryImage = nil
      self.trailingImage = nil
      self.trailingImageData = nil
      self.trailingImageTint = nil
      self._super?.setAccessoryImage(nil)
    }

    if playbackProgress != nil {
      self._super?.playbackProgress = playbackProgress!
      self.playbackProgress = playbackProgress
    }
    if isPlaying != nil {
      self._super?.isPlaying = isPlaying!
      self.isPlaying = isPlaying
    }
    if playingIndicatorLocation != nil {
      self.setPlayingIndicatorLocation(fromString: playingIndicatorLocation)
      if self.playingIndicatorLocation != nil {
        self._super?.playingIndicatorLocation = self.playingIndicatorLocation!
      }
    }
    if accessoryType != nil && (self.trailingImage ?? self.accessoryImage) == nil {
      self.setAccessoryType(fromString: accessoryType)
      if self.accessoryType != nil {
        self._super?.accessoryType = self.accessoryType!
      }
    }
  }

  private func setPlayingIndicatorLocation(fromString: String?) {
    if fromString == "leading" {
      self.playingIndicatorLocation = CPListItemPlayingIndicatorLocation.leading
    } else if fromString == "trailing" {
      self.playingIndicatorLocation = CPListItemPlayingIndicatorLocation.trailing
    }
  }

  private func setAccessoryType(fromString: String?) {
    if fromString == "cloud" {
      self.accessoryType = CPListItemAccessoryType.cloud
    } else if fromString == "disclosureIndicator" {
      self.accessoryType = CPListItemAccessoryType.disclosureIndicator
    } else {
      self.accessoryType = CPListItemAccessoryType.none
    }
  }
}

@available(iOS 14.0, *)
extension FCPListItem: FCPListTemplateItem {}
