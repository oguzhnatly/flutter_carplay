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
  private var imageTint: FCPImageTint?
  private var imageSize: FCPImageSize
  private var imageRequestID = UUID()
  var title: String
  var accessorySymbolName: String?
  var imageShape: CPListImageRowItemImageGridElement.Shape

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.image = obj["image"] as! String
    self.imageData = obj["imageData"] as? FlutterStandardTypedData
    self.imageTint = FCPImageTint(from: obj["imageTint"] as? [String: Any])
    self.imageSize = FCPImageSize(from: obj["imageSize"] as? [String: Any])
    self.title = obj["title"] as! String
    self.accessorySymbolName = obj["accessorySymbolName"] as? String
    self.imageShape = Self.getImageShape(fromString: obj["imageShape"] as? String)
  }

  var get: CPListImageRowItemElement {
    guard Thread.isMainThread else { return DispatchQueue.main.sync { self.get } }
    let slot = FCPImageSlot.element(CPListImageRowItemImageGridElement.maximumImageSize, imageSize)
    let listImageRowItemElement = CPListImageRowItemImageGridElement.init(
      image: makeSafeUIPlaceholder(slot: slot),
      imageShape: imageShape,
      title: title,
      accessorySymbolName: accessorySymbolName,
    )

    self._super = listImageRowItemElement
    imageRequestID = UUID()
    let requestID = imageRequestID
    loadUIImage(from: image, bytes: imageData, slot: slot, tint: imageTint) { [weak self, weak listImageRowItemElement] uiImage in
      guard let self = self, let element = listImageRowItemElement,
        self.imageRequestID == requestID, self._super === element else { return }
      element.image = uiImage
    }
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
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in self?.update(args: args) }
      return
    }
    let image = args["image"] as? String
    let imageData = args["imageData"] as? FlutterStandardTypedData
    let imageTint = FCPImageTint(from: args["imageTint"] as? [String: Any])
    let imageSize = FCPImageSize(from: args["imageSize"] as? [String: Any])
    let title = args["title"] as? String
    let accessorySymbolName = args["accessorySymbolName"] as? String

    let imageTintChanged = imageTint != self.imageTint
    let imageSizeChanged = imageSize.fraction != self.imageSize.fraction
    if let image = image, image != self.image || imageData?.data != self.imageData?.data
      || imageTintChanged || imageSizeChanged
    {
      let slot = FCPImageSlot.element(CPListImageRowItemImageGridElement.maximumImageSize, imageSize)
      self.image = image
      self.imageData = imageData
      self.imageTint = imageTint
      self.imageSize = imageSize
      imageRequestID = UUID()
      let requestID = imageRequestID
      self._super?.image = makeSafeUIPlaceholder(slot: slot)
      loadUIImage(from: image, bytes: imageData, slot: slot, tint: imageTint) { [weak self, weak element = self._super] uiImage in
        guard let self = self, let element = element,
          self.imageRequestID == requestID, self._super === element else { return }
        element.image = uiImage
      }
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
