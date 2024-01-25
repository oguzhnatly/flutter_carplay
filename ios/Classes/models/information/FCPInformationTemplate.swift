//
//  FCPInformationTemplate.swift
//  flutter_carplay
//
//  Created by Olaf Schneider on 15.02.22.
//

import CarPlay

/// A wrapper class for CPInformationTemplate with additional functionality.
@available(iOS 14.0, *)
class FCPInformationTemplate {
    // MARK: Properties

    /// The underlying CPInformationTemplate instance.
    private(set) var _super: CPInformationTemplate?

    /// The unique identifier for the information template.
    private(set) var elementId: String

    /// The layout style of the information template.
    private var layout: CPInformationTemplateLayout

    /// The title of the information template.
    private var title: String

    /// An array of CPInformationItem instances associated with the information template.
    private var informationItems: [CPInformationItem]

    /// An array of FCPInformationItem instances associated with the information template.
    private var objcInformationItems: [FCPInformationItem]

    /// An array of CPTextButton instances associated with the information template.
    private var actions: [CPTextButton]

    /// An array of FCPTextButton instances associated with the information template.
    private var objcActions: [FCPTextButton]

    /// The back button associated with the list template (optional).
    private var objcBackButton: FCPBarButton?

    /// The underlying CPBarButton instance associated with the back button.
    private var backButton: CPBarButton?

    /// An array of leading navigation bar buttons for the list template.
    private var leadingNavigationBarButtons: [FCPBarButton]

    /// An array of trailing navigation bar buttons for the list template.
    private var trailingNavigationBarButtons: [FCPBarButton]

    // MARK: Initializer

    /// Initializes an instance of FCPInformationTemplate with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the information template.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String,
              let layoutStringValue = obj["layout"] as? String,
              let titleValue = obj["title"] as? String
        else {
            fatalError("Missing required keys in dictionary for FCPInformationTemplate initialization.")
        }

        let informationItemsData = obj["informationItems"] as? [[String: Any]] ?? []
        let actionsData = obj["actions"] as? [[String: Any]] ?? []

        elementId = elementIdValue
        layout = layoutStringValue == "twoColumn" ? CPInformationTemplateLayout.twoColumn : CPInformationTemplateLayout.leading
        title = titleValue

        objcInformationItems = informationItemsData.map {
            FCPInformationItem(obj: $0)
        }
        informationItems = objcInformationItems.map {
            $0.get
        }

        objcActions = actionsData.map {
            FCPTextButton(obj: $0)
        }
        actions = objcActions.map {
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

    /// Returns the underlying CPInformationTemplate instance configured with the specified properties.
    var get: CPInformationTemplate {
        let informationTemplate = CPInformationTemplate(title: title, layout: layout, items: informationItems, actions: actions)

        var lBButtons: [CPBarButton] = []
        for button in leadingNavigationBarButtons {
            lBButtons.append(button.get)
        }

        var tBButtons: [CPBarButton] = []
        for button in trailingNavigationBarButtons {
            tBButtons.append(button.get)
        }

        informationTemplate.backButton = backButton
        informationTemplate.leadingNavigationBarButtons = lBButtons
        informationTemplate.trailingNavigationBarButtons = tBButtons
        informationTemplate.setFCPObject(self)

        _super = informationTemplate
        return informationTemplate
    }

    /// Updates the properties of the information template.
    ///
    /// - Parameters:
    ///   - items: The new array of FCPInformationItem instances.
    ///   - actions: The new array of FCPTextButton instances.
    ///   - leadingNavigationBarButtons: The new array of leading navigation bar buttons.
    ///   - trailingNavigationBarButtons: The new array of trailing navigation bar buttons.
    public func update(items: [FCPInformationItem]?, actions: [FCPTextButton]?, leadingNavigationBarButtons: [FCPBarButton]?, trailingNavigationBarButtons: [FCPBarButton]?) {
        if let items = items {
            objcInformationItems = items
            informationItems = items.map { $0.get }
            _super?.items = informationItems
        }

        if let actions = actions {
            objcActions = actions
            self.actions = actions.map { $0.get }
            _super?.actions = self.actions
        }

        if let leadingNavigationBarButtons = leadingNavigationBarButtons {
            self.leadingNavigationBarButtons = leadingNavigationBarButtons
            _super?.leadingNavigationBarButtons = leadingNavigationBarButtons.map { $0.get }
        }

        if let trailingNavigationBarButtons = trailingNavigationBarButtons {
            self.trailingNavigationBarButtons = trailingNavigationBarButtons
            _super?.trailingNavigationBarButtons = trailingNavigationBarButtons.map { $0.get }
        }

        _super?.setFCPObject(self)
    }
}

// MARK: Extensions

@available(iOS 14.0, *)
extension FCPInformationTemplate: FCPRootTemplate {}

@available(iOS 14.0, *)
extension FCPInformationTemplate: FCPTemplate {}
