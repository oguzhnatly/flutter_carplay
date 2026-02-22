//
//  FCPTextButton.swift
//  Runner
//
//  Created by Olaf Schneider on 17.02.22.
//

import CarPlay

@available(iOS 14.0, *)
class FCPTextButton {
  private(set) var _super: CPTextButton?
  private(set) var elementId: String
  private var title: String
  private var textstyle: CPTextButtonStyle

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as! String
    let textstyle = obj["textstyle"] as? String
    if textstyle == nil || textstyle == "normal" {
      self.textstyle = CPTextButtonStyle.normal
    } else {
      if textstyle == "cancel" {
        self.textstyle = CPTextButtonStyle.cancel
      } else {
        if textstyle == "confirm" {
          self.textstyle = CPTextButtonStyle.confirm
        } else {
          self.textstyle = CPTextButtonStyle.normal
        }
      }
    }
  }

  var get: CPTextButton {
    let textButton = CPTextButton.init(
      title: title, textStyle: self.textstyle,
      handler: { _ in
        DispatchQueue.main.async {
          FCPStreamHandlerPlugin.sendEvent(
            type: FCPChannelTypes.onTextButtonPressed, data: ["elementId": self.elementId])
        }
      })
    self._super = textButton
    return textButton
  }
}
