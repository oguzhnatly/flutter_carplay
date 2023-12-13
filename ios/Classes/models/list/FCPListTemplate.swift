//
//  FCPListTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPListTemplate {
    private(set) var _super: CPListTemplate?
    private(set) var elementId: String
    private var title: String?
    private var systemIcon: String
    private var sections: [CPListSection] = []
    private var objcSections: [FCPListSection] = []
    private var emptyViewTitleVariants: [String] = []
    private var emptyViewSubtitleVariants: [String] = []
    private var showsTabBadge: Bool = false
    private var templateType: FCPListTemplateTypes
    private var objcBackButton: FCPBarButton?
    private var backButton: CPBarButton?

    init(obj: [String: Any], templateType: FCPListTemplateTypes) {
        elementId = obj["_elementId"] as! String
        title = obj["title"] as? String
        systemIcon = obj["systemIcon"] as! String
        emptyViewTitleVariants = obj["emptyViewTitleVariants"] as? [String] ?? []
        emptyViewSubtitleVariants = obj["emptyViewSubtitleVariants"] as? [String] ?? []
        showsTabBadge = obj["showsTabBadge"] as! Bool
        self.templateType = templateType
        objcSections = (obj["sections"] as! [[String: Any]]).map {
            FCPListSection(obj: $0)
        }
        sections = objcSections.map {
            $0.get
        }
        let backButtonData = obj["backButton"] as? [String: Any]
        if backButtonData != nil {
            objcBackButton = FCPBarButton(obj: backButtonData!)
            backButton = objcBackButton?.get
        }
    }

    var get: CPListTemplate {
        let listTemplate = CPListTemplate(title: title, sections: sections)
        listTemplate.emptyViewTitleVariants = emptyViewTitleVariants
        listTemplate.emptyViewSubtitleVariants = emptyViewSubtitleVariants
        listTemplate.showsTabBadge = showsTabBadge
        listTemplate.tabImage = UIImage(systemName: systemIcon)
        if templateType == FCPListTemplateTypes.DEFAULT {
            listTemplate.backButton = backButton
        }
        _super = listTemplate
        return listTemplate
    }

    public func getSections() -> [FCPListSection] {
        return objcSections
    }
}

@available(iOS 14.0, *)
extension FCPListTemplate: FCPRootTemplate {}

@available(iOS 14.0, *)
extension FCPListTemplate: FCPTemplate {}
