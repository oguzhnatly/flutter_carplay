//
//  FCPListImageRowItem.swift
//  flutter_carplay
//

import CarPlay
import Flutter

@available(iOS 26.0, *)
final class FCPListImageRowItemGridElement {
  private(set) var _super: CPListImageRowItemGridElement?
  private(set) var elementId: String
  private(set) var image: String
  private var imageData: FlutterStandardTypedData?
  private var imageTint: FCPImageTint?

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.image = obj["image"] as! String
    self.imageData = obj["imageData"] as? FlutterStandardTypedData
    self.imageTint = FCPImageTint(from: obj["imageTint"] as? [String: Any])
  }

  var get: CPListImageRowItemElement {
    var listImageRowItemElement = CPListImageRowItemGridElement.init(
      image: makeSafeUIPlaceholder(),
    )

    loadUIImage(from: image, bytes: imageData, tint: imageTint) { uiImage in
      listImageRowItemElement.image = uiImage
    }

    self._super = listImageRowItemElement
    return listImageRowItemElement
  }

  public func update(args: [String: Any]) {
    let image = args["image"] as? String
    let imageData = args["imageData"] as? FlutterStandardTypedData
    let imageTint = FCPImageTint(from: args["imageTint"] as? [String: Any])

    let imageTintChanged = imageTint != self.imageTint
    if let image = image, image != self.image || imageTintChanged {
      self._super?.image = makeSafeUIPlaceholder()
      loadUIImage(from: image, bytes: imageData, tint: imageTint) { uiImage in
        self._super?.image = uiImage
      }
      self.image = image
      self.imageData = imageData
      self.imageTint = imageTint
    }
  }
}

@available(iOS 26.0, *)
extension FCPListImageRowItemGridElement: FCPListImageRowItemElement {}
