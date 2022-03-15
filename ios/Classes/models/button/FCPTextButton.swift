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
    private var style: CPTextButtonStyle
    
    init(obj: [String : Any]) {
        self.elementId = obj["_elementId"] as! String
        self.title = obj["title"] as! String
        let style = obj["style"] as? String
        if style == nil || style == "normal" {
            self.style = CPTextButtonStyle.normal
        } else {
            if style == "cancel"{
                self.style = CPTextButtonStyle.cancel
            }
            else {
                if style == "confirm"{
                    self.style = CPTextButtonStyle.confirm
                }
                else {
                    self.style = CPTextButtonStyle.normal
                }
            }
        }
    }
    
    var get: CPTextButton {
        let textButton = CPTextButton.init(title: title, textStyle:self.style, handler: { _ in
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onTextButtonPressed, data: ["elementId": self.elementId])
            }
        })
        self._super = textButton
        return textButton
    }
}
