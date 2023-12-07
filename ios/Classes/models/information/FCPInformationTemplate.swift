//
//  FCPInformationTemplate.swift
//  flutter_carplay
//
//  Created by Olaf Schneider on 15.02.22.
//

import CarPlay

@available(iOS 14.0, *)
class FCPInformationTemplate {
    private(set) var _super: CPInformationTemplate?
    private(set) var elementId: String
    private var title: String
    private var layout: CPInformationTemplateLayout

    private var informationItems: [CPInformationItem]
    private var objcInformationItems: [FCPInformationItem]

    private var actions: [CPTextButton]
    private var objcActions: [FCPTextButton]

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String

        layout = obj["layout"] as! String == "twoColumn"
            ? CPInformationTemplateLayout.twoColumn
            : CPInformationTemplateLayout.leading

        title = obj["title"] as! String

        objcInformationItems = (obj["informationItems"] as! [[String: Any]]).map {
            FCPInformationItem(obj: $0)
        }
        informationItems = objcInformationItems.map {
            $0.get
        }

        objcActions = (obj["actions"] as! [[String: Any]]).map {
            FCPTextButton(obj: $0)
        }
        actions = objcActions.map {
            $0.get
        }
    }

    var get: CPInformationTemplate {
        let informationTemplate = CPInformationTemplate(title: title, layout: layout, items: informationItems, actions: actions)
        return informationTemplate
    }
}

@available(iOS 14.0, *)
extension FCPInformationTemplate: FCPRootTemplate {}
