//
//  FCPAlertAction.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPAlertAction {
    private(set) var _super: CPAlertAction?
    private(set) var elementId: String
    private var title: String
    private var style: CPAlertAction.Style
    private var handlerType: FCPAlertActionTypes

    init(obj: [String: Any], type: FCPAlertActionTypes) {
        elementId = obj["_elementId"] as! String
        title = obj["title"] as! String
        let style = obj["style"] as! String
        self.style = style.elementsEqual("normal")
            ? CPAlertAction.Style.default
            : style.elementsEqual("destructive")
            ? CPAlertAction.Style.destructive
            : CPAlertAction.Style.cancel
        handlerType = type
    }

    var get: CPAlertAction {
        let alertAction = CPAlertAction(title: title, style: style, handler: { _ in
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onAlertActionPressed, data: ["elementId": self.elementId])
            }
        })
        _super = alertAction
        return alertAction
    }
}
