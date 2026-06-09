//
//  FCPListImageRowItem.swift
//  flutter_carplay
//

import CarPlay
import Flutter

@available(iOS 26.0, *)
final class FCPListImageRowItemRowElement {
  private(set) var _super: CPListImageRowItemRowElement?
  private(set) var elementId: String
  private(set) var image: String
  private var imageData: FlutterStandardTypedData?
  private var imageTint: FCPImageTint?
  var title: String?
  var subtitle: String?

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.image = obj["image"] as! String
    self.imageData = obj["imageData"] as? FlutterStandardTypedData
    self.imageTint = FCPImageTint(from: obj["imageTint"] as? [String: Any])
    self.title = obj["title"] as? String
    self.subtitle = obj["subtitle"] as? String
  }

  var get: CPListImageRowItemElement {
    var listImageRowItemElement = CPListImageRowItemRowElement.init(
      image: makeSafeUIPlaceholder(),
      title: title,
      subtitle: subtitle,
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
    let title = args["title"] as? String
    let subtitle = args["subtitle"] as? String

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

    if let title = title {
      self.title = title
      self._super?.title = title
    }

    if let subtitle = subtitle {
      self.subtitle = subtitle
      self._super?.subtitle = subtitle
    }
  }
}

@available(iOS 26.0, *)
extension FCPListImageRowItemRowElement: FCPListImageRowItemElement {}
