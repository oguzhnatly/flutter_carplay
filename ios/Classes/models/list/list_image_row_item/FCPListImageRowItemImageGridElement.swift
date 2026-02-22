//
//  FCPListImageRowItem.swift
//  flutter_carplay
//

import CarPlay

@available(iOS 26.0, *)
final class FCPListImageRowItemImageGridElement {
  private(set) var _super: CPListImageRowItemImageGridElement?
  private(set) var elementId: String
  private(set) var image: String
  var title: String
  var accessorySymbolName: String?
  var imageShape: CPListImageRowItemImageGridElement.Shape

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.image = obj["image"] as! String
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

    let imageSource = self.image.toImageSource()
    loadUIImageAsync(from: imageSource) { uiImage in
      if let uiImage = uiImage {
        listImageRowItemElement.image = uiImage
      }
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
    let title = args["title"] as? String
    let accessorySymbolName = args["accessorySymbolName"] as? String

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
