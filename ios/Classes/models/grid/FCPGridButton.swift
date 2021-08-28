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
    let gridButton = CPGridButton.init(titleVariants: self.titleVariants,
                                       image: UIImage().fromFlutterAsset(name: self.image),
                                       handler: { _ in
      DispatchQueue.main.async {
        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onGridButtonPressed,
                                         data: ["elementId": self.elementId])
      }
    })
    gridButton.isEnabled = true
    self._super = gridButton
    return gridButton
  }
}
