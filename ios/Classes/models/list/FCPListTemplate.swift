//
//  FCPListTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

/// A wrapper class for CPListTemplate with additional functionality.
@available(iOS 14.0, *)
class FCPListTemplate {
    // MARK: Properties

    /// The underlying CPListTemplate instance.
    private(set) var _super: CPListTemplate?

    /// The unique identifier for the list template.
    private(set) var elementId: String

    /// The title text for the list template (optional).
    private var title: String?

    /// The system icon for the list template (optional).
    private var systemIcon: String?

    /// An array of CPListSection instances associated with the list template.
    private var sections: [CPListSection] = []

    /// An array of FCPListSection instances associated with the list template.
    private var objcSections: [FCPListSection] = []

    /// An array of title variants for the empty view.
    private var emptyViewTitleVariants: [String] = []

    /// An array of subtitle variants for the empty view.
    private var emptyViewSubtitleVariants: [String] = []

    /// Indicates whether the list template shows a tab badge.
    private var showsTabBadge: Bool = false

    /// The template type of the list template.
    private var templateType: FCPListTemplateTypes

    /// The back button associated with the list template (optional).
    private var objcBackButton: FCPBarButton?

    /// The underlying CPBarButton instance associated with the back button.
    private var backButton: CPBarButton?

    /// An array of leading navigation bar buttons for the list template.
    private var leadingNavigationBarButtons: [FCPBarButton]

    /// An array of trailing navigation bar buttons for the list template.
    private var trailingNavigationBarButtons: [FCPBarButton]

    // MARK: Initializer

    /// Initializes an instance of FCPListTemplate with the provided parameters.
    ///
    /// - Parameters:
    ///   - obj: A dictionary containing information about the list template.
    ///   - templateType: The template type of the list template.
    init(obj: [String: Any], templateType: FCPListTemplateTypes) {
        guard let elementIdValue = obj["_elementId"] as? String else {
            fatalError("Missing required keys in dictionary for FCPListTemplate initialization.")
        }

        elementId = elementIdValue
        title = obj["title"] as? String
        systemIcon = obj["systemIcon"] as? String
        emptyViewTitleVariants = obj["emptyViewTitleVariants"] as? [String] ?? []
        emptyViewSubtitleVariants = obj["emptyViewSubtitleVariants"] as? [String] ?? []
        showsTabBadge = obj["showsTabBadge"] as? Bool ?? false
        self.templateType = templateType
        objcSections = (obj["sections"] as? [[String: Any]] ?? []).map {
            FCPListSection(obj: $0)
        }
        sections = objcSections.map {
            $0.get
        }
        if let backButtonData = obj["backButton"] as? [String: Any] {
            objcBackButton = FCPBarButton(obj: backButtonData)
            backButton = objcBackButton?.get
        }
        leadingNavigationBarButtons = (obj["leadingNavigationBarButtons"] as? [[String: Any]] ?? []).map {
            FCPBarButton(obj: $0)
        }
        trailingNavigationBarButtons = (obj["trailingNavigationBarButtons"] as? [[String: Any]] ?? []).map {
            FCPBarButton(obj: $0)
        }
    }

    // MARK: Computed Property

    /// Returns the underlying CPListTemplate instance configured with the specified properties.
    var get: CPListTemplate {
        // Implementation details for returning CPListTemplate instance
        let listTemplate = CPListTemplate(title: title, sections: sections)
        listTemplate.setFCPObject(self)
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

    // MARK: Public Methods

    /// Retrieves an array of FCPListSection instances associated with the list template.
    ///
    /// - Returns: An array of FCPListSection instances.
    public func getSections() -> [FCPListSection] {
        return objcSections
    }

    /// Updates the properties of the list template.
    ///
    /// - Parameters:
    ///   - emptyViewTitleVariants: The new title variants for the empty view.
    ///   - emptyViewSubtitleVariants: The new subtitle variants for the empty view.
    ///   - sections: The new array of FCPListSection instances.
    ///   - leadingNavigationBarButtons: The new array of leading navigation bar buttons.
    ///   - trailingNavigationBarButtons: The new array of trailing navigation bar buttons.
    public func update(emptyViewTitleVariants: [String]?, emptyViewSubtitleVariants: [String]?, sections: [FCPListSection]?, leadingNavigationBarButtons: [FCPBarButton]?, trailingNavigationBarButtons: [FCPBarButton]?) {
        if let _emptyViewTitleVariants = emptyViewTitleVariants {
            self.emptyViewTitleVariants = _emptyViewTitleVariants
            _super?.emptyViewTitleVariants = _emptyViewTitleVariants
        }

        if let _emptyViewSubtitleVariants = emptyViewSubtitleVariants {
            self.emptyViewSubtitleVariants = _emptyViewSubtitleVariants
            _super?.emptyViewSubtitleVariants = _emptyViewSubtitleVariants
        }

        if let _sections = sections {
            objcSections = _sections
            self.sections = _sections.map {
                $0.get
            }
            _super?.updateSections(self.sections)
        }

        if let _leadingNavigationBarButtons = leadingNavigationBarButtons {
            self.leadingNavigationBarButtons = _leadingNavigationBarButtons
            _super?.leadingNavigationBarButtons = _leadingNavigationBarButtons.map {
                $0.get
            }
        }

        if let _trailingNavigationBarButtons = trailingNavigationBarButtons {
            self.trailingNavigationBarButtons = _trailingNavigationBarButtons
            _super?.trailingNavigationBarButtons = _trailingNavigationBarButtons.map {
                $0.get
            }
        }
        _super?.setFCPObject(self)
    }
}

@available(iOS 14.0, *)
extension FCPListTemplate: FCPRootTemplate {}

@available(iOS 14.0, *)
extension FCPListTemplate: FCPTemplate {}
