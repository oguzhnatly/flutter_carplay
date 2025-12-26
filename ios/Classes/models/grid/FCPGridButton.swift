//
//  FCPGridButton.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPGridButton {
  private(set) var _super: CPGridButton?
  private(set) var elementId: String
  private var titleVariants: [String]
  private var image: String
  
  init(obj: [String : Any]) {
    self.elementId = obj["_elementId"] as! String
    self.titleVariants = obj["titleVariants"] as! [String]
    self.image = obj["image"] as! String
  }
  
  var get: CPGridButton {
    var gridButton: CPGridButton!
    let image: UIImage

    if #available(iOS 26.0, *) {
      image = makeSafeUIPlaceholder();
    } else {
      let imageSource = self.image.toImageSource()
      image = makeUIImage(from: imageSource)
    }

    gridButton = CPGridButton(
      titleVariants: self.titleVariants,
      image: image,
      handler: { _ in
        DispatchQueue.main.async {
          FCPStreamHandlerPlugin.sendEvent(
            type: FCPChannelTypes.onGridButtonPressed,
            data: ["elementId": self.elementId]
          )
        }
      }
    )

    if #available(iOS 26.0, *) {
      let imageSource = self.image.toImageSource()
      loadUIImageAsync(from: imageSource) { uiImage in
        if let uiImage = uiImage {
          gridButton.updateImage(uiImage)
        }
      }
    }

    gridButton.isEnabled = true
    self._super = gridButton
    return gridButton
  }
}
