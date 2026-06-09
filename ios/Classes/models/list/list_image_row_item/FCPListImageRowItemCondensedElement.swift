//
//  FCPListImageRowItem.swift
//  flutter_carplay
//

import CarPlay
import Flutter

@available(iOS 26.0, *)
final class FCPListImageRowItemCondensedElement {
  private(set) var _super: CPListImageRowItemCondensedElement?
  private(set) var elementId: String
  private(set) var image: String
  private var imageData: FlutterStandardTypedData?
  private var imageTint: FCPImageTint?
  var imageShape: CPListImageRowItemCondensedElement.Shape
  var title: String
  var subtitle: String?
  var accessorySymbolName: String?

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.image = obj["image"] as! String
    self.imageData = obj["imageData"] as? FlutterStandardTypedData
    self.imageTint = FCPImageTint(from: obj["imageTint"] as? [String: Any])
    self.title = obj["title"] as! String
    self.subtitle = obj["subtitle"] as? String
    self.imageShape = Self.getImageShape(fromString: obj["imageShape"] as? String)
    self.accessorySymbolName = obj["accessorySymbolName"] as? String
  }

  var get: CPListImageRowItemElement {
    var listImageRowItemElement = CPListImageRowItemCondensedElement.init(
      image: makeSafeUIPlaceholder(),
      imageShape: imageShape,
      title: title,
      subtitle: subtitle,
      accessorySymbolName: accessorySymbolName,
    )

    loadUIImage(from: image, bytes: imageData, tint: imageTint) { uiImage in
      listImageRowItemElement.image = uiImage
    }

    self._super = listImageRowItemElement
    return listImageRowItemElement
  }

  public static func getImageShape(fromString: String?) -> CPListImageRowItemCondensedElement.Shape
  {
    guard let fromString = fromString else {
      return .circular
    }
    switch fromString {
    case "circular":
      return .circular
    case "roundedRectangle":
      return .roundedRectangle
    default:
      return .circular
    }
  }

  public func update(args: [String: Any]) {
    let image = args["image"] as? String
    let imageData = args["imageData"] as? FlutterStandardTypedData
    let imageTint = FCPImageTint(from: args["imageTint"] as? [String: Any])
    let title = args["title"] as? String
    let subtitle = args["subtitle"] as? String
    let accessorySymbolName = args["accessorySymbolName"] as? String

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

    if let accessorySymbolName = accessorySymbolName {
      self.accessorySymbolName = accessorySymbolName
      self._super?.accessorySymbolName = accessorySymbolName
    }
  }
}

@available(iOS 26.0, *)
extension FCPListImageRowItemCondensedElement: FCPListImageRowItemElement {}
