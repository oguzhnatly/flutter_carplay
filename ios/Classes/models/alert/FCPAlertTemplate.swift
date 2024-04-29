//
//  FCPAlertTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPAlertTemplate {
    private(set) var _super: CPAlertTemplate?
    private(set) var elementId: String
    private var titleVariants: [String]
    private var actions: [CPAlertAction]
    private var objcActions: [FCPAlertAction]

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        titleVariants = obj["titleVariants"] as! [String]
        objcActions = (obj["actions"] as! [[String: Any]]).map {
            FCPAlertAction(obj: $0, type: FCPAlertActionTypes.ALERT)
        }
        actions = objcActions.map {
            $0.get
        }
    }

    var get: CPAlertTemplate {
        let alertTemplate = CPAlertTemplate(titleVariants: titleVariants, actions: actions)
        _super = alertTemplate
        return alertTemplate
    }
}

@available(iOS 14.0, *)
extension FCPAlertTemplate: FCPPresentTemplate {}
