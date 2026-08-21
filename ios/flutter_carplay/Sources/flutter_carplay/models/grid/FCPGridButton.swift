//
//  FCPGridButton.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import Flutter

@available(iOS 14.0, *)
class FCPGridButton {
  private(set) var _super: CPGridButton?
  private(set) var elementId: String
  private var titleVariants: [String]
  private var image: String
  private var imageData: FlutterStandardTypedData?
  private var imageTint: FCPImageTint?
  private var imageSize: FCPImageSize
  private var isOnPressListenerActive: Bool

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.titleVariants = obj["titleVariants"] as! [String]
    self.image = obj["image"] as! String
    self.imageData = obj["imageData"] as? FlutterStandardTypedData
    self.imageTint = FCPImageTint(from: obj["imageTint"] as? [String: Any])
    self.imageSize = FCPImageSize(from: obj["imageSize"] as? [String: Any])
    self.isOnPressListenerActive = obj["onPress"] as? Bool ?? false
  }

  var get: CPGridButton {
    var gridButton: CPGridButton!
    let slot = FCPImageSlot.gridButton(imageSize)
    let image: UIImage
    let bytesImage = makeUIImage(fromBytes: imageData)
    let usesAsyncImage: Bool
    if #available(iOS 26.0, *), bytesImage == nil {
      usesAsyncImage = true
    } else {
      usesAsyncImage = false
    }

    if let bytesImage = bytesImage {
      image = bytesImage.preparedForCarPlay(slot: slot, tint: imageTint)
    } else if usesAsyncImage {
      image = makeSafeUIPlaceholder(slot: slot)
    } else {
      image = makeUIImage(from: self.image.toImageSource())
        .preparedForCarPlay(slot: slot, tint: imageTint)
    }

    gridButton = CPGridButton(
      titleVariants: self.titleVariants,
      image: image,
      handler: { _ in
        if self.isOnPressListenerActive {
          DispatchQueue.main.async {
            FCPStreamHandlerPlugin.sendEvent(
              type: FCPChannelTypes.onGridButtonPressed,
              data: ["elementId": self.elementId]
            )
          }
        }
      }
    )

    if usesAsyncImage {
      loadUIImage(from: self.image, bytes: imageData, slot: slot, tint: imageTint) { uiImage in
        gridButton.perform(Selector("updateImage:"), with: uiImage)
      }
    }

    gridButton.isEnabled = true
    self._super = gridButton
    return gridButton
  }
}
