//
//  FCPActionSheetTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 25.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPActionSheetTemplate {
    private(set) var _super: CPActionSheetTemplate?
    private(set) var elementId: String
    private var title: String?
    private var message: String?
    private var actions: [CPAlertAction]
    private var objcActions: [FCPAlertAction]

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        title = obj["title"] as? String
        message = obj["message"] as? String
        objcActions = (obj["actions"] as! [[String: Any]]).map {
            FCPAlertAction(obj: $0, type: FCPAlertActionTypes.ACTION_SHEET)
        }
        actions = objcActions.map {
            $0.get
        }
    }

    var get: CPActionSheetTemplate {
        let actionSheetTemplate = CPActionSheetTemplate(title: title, message: message, actions: actions)
        _super = actionSheetTemplate
        return actionSheetTemplate
    }
}

@available(iOS 14.0, *)
extension FCPActionSheetTemplate: FCPPresentTemplate {}

@available(iOS 14.0, *)
extension FCPActionSheetTemplate: FCPTemplate {}
