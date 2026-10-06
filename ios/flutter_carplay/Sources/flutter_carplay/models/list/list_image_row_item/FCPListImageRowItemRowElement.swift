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
  private var imageSize: FCPImageSize
  private var imageRequestID = UUID()
  var title: String?
  var subtitle: String?

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.image = obj["image"] as! String
    self.imageData = obj["imageData"] as? FlutterStandardTypedData
    self.imageTint = FCPImageTint(from: obj["imageTint"] as? [String: Any])
    self.imageSize = FCPImageSize(from: obj["imageSize"] as? [String: Any])
    self.title = obj["title"] as? String
    self.subtitle = obj["subtitle"] as? String
  }

  var get: CPListImageRowItemElement {
    guard Thread.isMainThread else { return DispatchQueue.main.sync { self.get } }
    let slot = FCPImageSlot.element(CPListImageRowItemRowElement.maximumImageSize, imageSize)
    let listImageRowItemElement = CPListImageRowItemRowElement.init(
      image: makeSafeUIPlaceholder(slot: slot),
      title: title,
      subtitle: subtitle,
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
    let subtitle = args["subtitle"] as? String

    let imageTintChanged = imageTint != self.imageTint
    let imageSizeChanged = imageSize.fraction != self.imageSize.fraction
    if let image = image, image != self.image || imageData?.data != self.imageData?.data
      || imageTintChanged || imageSizeChanged
    {
      let slot = FCPImageSlot.element(CPListImageRowItemRowElement.maximumImageSize, imageSize)
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

    if let subtitle = subtitle {
      self.subtitle = subtitle
      self._super?.subtitle = subtitle
    }
  }
}

@available(iOS 26.0, *)
extension FCPListImageRowItemRowElement: FCPListImageRowItemElement {}
