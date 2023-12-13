//
//  FCPGridTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPGridTemplate {
    private(set) var _super: CPGridTemplate?
    private(set) var elementId: String
    private var title: String
    private var buttons: [CPGridButton]
    private var objcButtons: [FCPGridButton]

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        title = obj["title"] as! String
        objcButtons = (obj["buttons"] as! [[String: Any]]).map {
            FCPGridButton(obj: $0)
        }
        buttons = objcButtons.map {
            $0.get
        }
    }

    var get: CPGridTemplate {
        let gridTemplate = CPGridTemplate(title: title, gridButtons: buttons)
        _super = gridTemplate
        return gridTemplate
    }
}

@available(iOS 14.0, *)
extension FCPGridTemplate: FCPRootTemplate {}

@available(iOS 14.0, *)
extension FCPGridTemplate: FCPTemplate {}
