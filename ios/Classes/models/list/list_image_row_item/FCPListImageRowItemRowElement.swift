//
//  FCPListImageRowItem.swift
//  flutter_carplay
//

import CarPlay

@available(iOS 26.0, *)
final class FCPListImageRowItemRowElement {
  private(set) var _super: CPListImageRowItemRowElement?
  private(set) var elementId: String
  private(set) var image: String
  var title: String?
  var subtitle: String?

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.image = obj["image"] as! String
    self.title = obj["title"] as? String
    self.subtitle = obj["subtitle"] as? String
  }

  var get: CPListImageRowItemElement {
    var listImageRowItemElement = CPListImageRowItemRowElement.init(
      image: makeSafeUIPlaceholder(),
      title: title,
      subtitle: subtitle,
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
    let title = args["title"] as? String
    let subtitle = args["subtitle"] as? String

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
