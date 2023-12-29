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
    private var systemIcon: String?
    private var sections: [CPListSection] = []
    private var objcSections: [FCPListSection] = []
    private var emptyViewTitleVariants: [String] = []
    private var emptyViewSubtitleVariants: [String] = []
    private var showsTabBadge: Bool = false
    private var templateType: FCPListTemplateTypes
    private var objcBackButton: FCPBarButton?
    private var backButton: CPBarButton?
    private var leadingNavigationBarButtons: [FCPBarButton]
    private var trailingNavigationBarButtons: [FCPBarButton]

    init(obj: [String: Any], templateType: FCPListTemplateTypes) {
        elementId = obj["_elementId"] as! String
        title = obj["title"] as? String
        systemIcon = obj["systemIcon"] as? String
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
        leadingNavigationBarButtons = (obj["leadingNavigationBarButtons"] as! [[String: Any]]).map {
            FCPBarButton(obj: $0)
        }
        trailingNavigationBarButtons = (obj["trailingNavigationBarButtons"] as! [[String: Any]]).map {
            FCPBarButton(obj: $0)
        }
    }

    var get: CPListTemplate {
        let listTemplate = CPListTemplate(title: title, sections: sections)
        listTemplate.setFCPTemplate(self)
        listTemplate.emptyViewTitleVariants = emptyViewTitleVariants
        listTemplate.emptyViewSubtitleVariants = emptyViewSubtitleVariants
        listTemplate.showsTabBadge = showsTabBadge
        if let icon = systemIcon {
            listTemplate.tabImage = UIImage(systemName: icon)
        }

        if templateType == FCPListTemplateTypes.DEFAULT {
            listTemplate.backButton = backButton
        }

        var lBButtons: [CPBarButton] = []
        for button in leadingNavigationBarButtons {
            lBButtons.append(button.get)
        }

        var tBButtons: [CPBarButton] = []
        for button in trailingNavigationBarButtons {
            tBButtons.append(button.get)
        }
        listTemplate.leadingNavigationBarButtons = lBButtons
        listTemplate.trailingNavigationBarButtons = tBButtons
        _super = listTemplate
        return listTemplate
    }

    public func getSections() -> [FCPListSection] {
        return objcSections
    }

    public func update(emptyViewTitleVariants: [String]?, emptyViewSubtitleVariants: [String]?, sections: [FCPListSection]?, leadingNavigationBarButtons: [FCPBarButton]?, trailingNavigationBarButtons: [FCPBarButton]?) {
        if emptyViewTitleVariants != nil {
            self.emptyViewTitleVariants = emptyViewTitleVariants!
            _super?.emptyViewTitleVariants = emptyViewTitleVariants!
        }

        if emptyViewSubtitleVariants != nil {
            self.emptyViewSubtitleVariants = emptyViewSubtitleVariants!
            _super?.emptyViewSubtitleVariants = emptyViewSubtitleVariants!
        }

        if sections != nil {
            objcSections = sections!
            self.sections = sections!.map {
                $0.get
            }
            _super?.updateSections(self.sections)
        }

        if leadingNavigationBarButtons != nil {
            self.leadingNavigationBarButtons = leadingNavigationBarButtons!
            _super?.leadingNavigationBarButtons = leadingNavigationBarButtons!.map {
                $0.get
            }
        }

        if trailingNavigationBarButtons != nil {
            self.trailingNavigationBarButtons = trailingNavigationBarButtons!
            _super?.trailingNavigationBarButtons = trailingNavigationBarButtons!.map {
                $0.get
            }
        }
        _super?.setFCPTemplate(self)
    }
}

@available(iOS 14.0, *)
extension FCPListTemplate: FCPRootTemplate {}

@available(iOS 14.0, *)
extension FCPListTemplate: FCPTemplate {}
