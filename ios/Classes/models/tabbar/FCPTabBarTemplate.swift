//
//  FCPTabBarTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

/// A custom template representing a tab bar on CarPlay.
@available(iOS 14.0, *)
class FCPTabBarTemplate {
    // MARK: Properties

    /// The unique identifier for the tab bar template.
    private(set) var elementId: String

    /// The title of the tab bar.
    private var title: String?

    /// The list of templates associated with the tab bar.
    private var templates: [CPTemplate]

    /// The list of custom templates associated with the tab bar.
    private var objcTemplates: [FCPListTemplate]

    // MARK: Initialization

    /// Initializes a new instance of `FCPTabBarTemplate` with the specified parameters.
    ///
    /// - Parameter obj: A dictionary containing the properties of the tab bar template.
    init(obj: [String: Any]) {
        guard let elementId = obj["_elementId"] as? String else {
            fatalError("Missing required property 'elementId' for FCPTabBarTemplate initialization.")
        }

        self.elementId = elementId
        title = obj["title"] as? String
        objcTemplates = (obj["templates"] as? [[String: Any]] ?? []).compactMap {
            FCPListTemplate(obj: $0, templateType: FCPListTemplateTypes.PART_OF_GRID_TEMPLATE)
        }
        templates = objcTemplates.map { $0.get }
    }

    // MARK: Methods

    /// Returns a `CPTabBarTemplate` object representing the tab bar template.
    ///
    /// - Returns: A `CPTabBarTemplate` object.
    var get: CPTabBarTemplate {
        let tabBarTemplate = CPTabBarTemplate(templates: templates)
        tabBarTemplate.setFCPObject(self)
        tabBarTemplate.tabTitle = title
        return tabBarTemplate
    }

    /// Returns the list of custom templates associated with the tab bar.
    ///
    /// - Returns: An array of `FCPListTemplate` objects.
    public func getTemplates() -> [FCPListTemplate] {
        return objcTemplates
    }
}

@available(iOS 14.0, *)
extension FCPTabBarTemplate: FCPRootTemplate {}

@available(iOS 14.0, *)
extension FCPTabBarTemplate: FCPTemplate {}
