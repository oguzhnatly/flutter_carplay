//
//  FCPListImageRowItem.swift
//  flutter_carplay
//

import CarPlay
import Flutter

@available(iOS 26.0, *)
final class FCPListImageRowItemImageGridElement {
  private(set) var _super: CPListImageRowItemImageGridElement?
  private(set) var elementId: String
  private(set) var image: String
  private var imageData: FlutterStandardTypedData?
  var title: String
  var accessorySymbolName: String?
  var imageShape: CPListImageRowItemImageGridElement.Shape

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.image = obj["image"] as! String
    self.imageData = obj["imageData"] as? FlutterStandardTypedData
    self.title = obj["title"] as! String
    self.accessorySymbolName = obj["accessorySymbolName"] as? String
    self.imageShape = Self.getImageShape(fromString: obj["imageShape"] as? String)
  }

  var get: CPListImageRowItemElement {
    var listImageRowItemElement = CPListImageRowItemImageGridElement.init(
      image: makeSafeUIPlaceholder(),
      imageShape: imageShape,
      title: title,
      accessorySymbolName: accessorySymbolName,
    )

    loadUIImage(from: image, bytes: imageData) { uiImage in
      listImageRowItemElement.image = uiImage
    }

    self._super = listImageRowItemElement
    return listImageRowItemElement
  }

  public static func getImageShape(fromString: String?) -> CPListImageRowItemImageGridElement.Shape
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
    let title = args["title"] as? String
    let accessorySymbolName = args["accessorySymbolName"] as? String

    if let image = image, image != self.image {
      self._super?.image = makeSafeUIPlaceholder()
      loadUIImage(from: image, bytes: imageData) { uiImage in
        self._super?.image = uiImage
      }
      self.image = image
      self.imageData = imageData
    }

    if let title = title {
      self.title = title
      self._super?.title = title
    }

    if let accessorySymbolName = accessorySymbolName {
      self.accessorySymbolName = accessorySymbolName
      self._super?.accessorySymbolName = accessorySymbolName
    }
  }
}

@available(iOS 26.0, *)
extension FCPListImageRowItemImageGridElement: FCPListImageRowItemElement {}
