//
//  FCPBarButton.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 25.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPBarButton {
  private(set) var _super: CPBarButton?
  private(set) var elementId: String
  private var title: String
  private var style: CPBarButtonStyle
  
  init(obj: [String : Any]) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as! String
    let style = obj["style"] as? String
    if style == nil || style == "rounded" {
      self.style = CPBarButtonStyle.rounded
    } else {
      self.style = CPBarButtonStyle.none
    }
  }
  
  var get: CPBarButton {
    let barButton = CPBarButton.init(title: title, handler: { _ in
      DispatchQueue.main.async {
        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onBarButtonPressed, data: ["elementId": self.elementId])
      }
    })
    barButton.buttonStyle = self.style
    self._super = barButton
    return barButton
  }
}
