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

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.image = obj["image"] as! String
    self.imageData = obj["imageData"] as? FlutterStandardTypedData
  }

  var get: CPListImageRowItemElement {
    var listImageRowItemElement = CPListImageRowItemGridElement.init(
      image: makeSafeUIPlaceholder(),
    )

    let imageSource = self.image.toImageSource()
    if let bytesImage = makeUIImage(fromBytes: imageData) {
      listImageRowItemElement.image = bytesImage
    } else {
      loadUIImageAsync(from: imageSource) { uiImage in
        if let uiImage = uiImage {
          listImageRowItemElement.image = uiImage
        }
      }
    }

    self._super = listImageRowItemElement
    return listImageRowItemElement
  }

  public func update(args: [String: Any]) {
    let image = args["image"] as? String
    let imageData = args["imageData"] as? FlutterStandardTypedData

    if let image = image, image != self.image {
      self._super?.image = makeSafeUIPlaceholder()
      if let bytesImage = makeUIImage(fromBytes: imageData) {
        self._super?.image = bytesImage
      } else {
        let imageSource = image.toImageSource()
        loadUIImageAsync(from: imageSource) { uiImage in
          if let uiImage = uiImage {
            self._super?.image = uiImage
          }
        }
      }
      self.image = image
      self.imageData = imageData
    }
  }
}

@available(iOS 26.0, *)
extension FCPListImageRowItemGridElement: FCPListImageRowItemElement {}
