//
//  FCPListImageRowItem.swift
//  flutter_carplay
//

import CarPlay

@available(iOS 26.0, *)
final class FCPListImageRowItemCardElement {
  private(set) var _super: CPListImageRowItemCardElement?
  private(set) var elementId: String
  private(set) var image: String
  var title: String?
  var subtitle: String?
  var tintColor: UIColor?
  var showsImageFullHeight: Bool

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.image = obj["image"] as! String
    self.title = obj["title"] as? String
    self.subtitle = obj["subtitle"] as? String
    if let tintColor = obj["tintColor"] as? [String: Any],
      let tintColor = UIColor(from: tintColor)
    {
      self.tintColor = tintColor
    }
    self.showsImageFullHeight = obj["showsImageFullHeight"] as! Bool
  }

  var get: CPListImageRowItemElement {
    var listImageRowItemElement = CPListImageRowItemCardElement.init(
      image: makeSafeUIPlaceholder(),
      showsImageFullHeight: showsImageFullHeight,
      title: title,
      subtitle: subtitle,
      tintColor: tintColor,
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

  public func update(args: [String: Any]) {
    let image = args["image"] as? String
    let title = args["title"] as? String
    let subtitle = args["subtitle"] as? String
    let tintColor = args["tintColor"] as? [String: Any]

    if let image = image, image != self.image {
      self._super?.image = makeSafeUIPlaceholder()
      let imageSource = image.toImageSource()
      loadUIImageAsync(from: imageSource) { uiImage in
        if let uiImage = uiImage {
          self._super?.image = uiImage
        }
      }
      self.image = image
    }

    if let title = title {
      self.title = title
      self._super?.title = title
    }

    if let subtitle = subtitle {
      self.subtitle = subtitle
      self._super?.subtitle = subtitle
    }

    if let tintColor = tintColor,
      let tintColor = UIColor(from: tintColor)
    {
      self.tintColor = tintColor
      self._super?.tintColor = tintColor
    }
  }
}

@available(iOS 26.0, *)
extension FCPListImageRowItemCardElement: FCPListImageRowItemElement {}
