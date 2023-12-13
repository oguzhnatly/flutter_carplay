//
//  FCPTabBarTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPTabBarTemplate {
    private(set) var elementId: String
    private var title: String?
    private var templates: [CPTemplate]
    private var objcTemplates: [FCPListTemplate]

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        title = obj["title"] as? String
        objcTemplates = (obj["templates"] as! [[String: Any]]).map {
            FCPListTemplate(obj: $0, templateType: FCPListTemplateTypes.PART_OF_GRID_TEMPLATE)
        }
        templates = objcTemplates.map {
            $0.get
        }
    }

    var get: CPTabBarTemplate {
        let tabBarTemplate = CPTabBarTemplate(templates: templates)
        tabBarTemplate.tabTitle = title
        return tabBarTemplate
    }

    public func getTemplates() -> [FCPListTemplate] {
        return objcTemplates
    }
}

@available(iOS 14.0, *)
extension FCPTabBarTemplate: FCPRootTemplate {}

@available(iOS 14.0, *)
extension FCPTabBarTemplate: FCPTemplate {}
