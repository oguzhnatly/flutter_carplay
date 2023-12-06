//
//  FCPMapButton.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 25.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPMapButton {
  private(set) var _super: CPMapButton?
  private(set) var elementId: String
  private var isEnabled: Bool = true
  private var isHidden: Bool = false
  private var image: UIImage?
  private var focusedImage: UIImage?

  init(obj: [String : Any]) {
    self.elementId = obj["_elementId"] as! String
    self.isEnabled = obj["isEnabled"] as! Bool
    self.isHidden = obj["isHidden"] as! Bool
    self.image = obj["image"] as? UIImage
    self.focusedImage = obj["focusedImage"] as? UIImage

  }

  var get: CPMapButton {
    let mapButton = CPMapButton { _ in
          DispatchQueue.main.async {
            FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onMapButtonPressed, data: ["elementId": self.elementId])
          }
        }
        mapButton.isHidden = isHidden
        mapButton.isEnabled = isEnabled
        mapButton.image = image
        mapButton.focusedImage = focusedImage

    self._super = mapButton
    return mapButton
  }
}
