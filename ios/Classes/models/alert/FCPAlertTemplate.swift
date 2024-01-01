//
//  FCPAlertTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

/// A wrapper class for CPAlertTemplate with additional functionality.
@available(iOS 14.0, *)
class FCPAlertTemplate {
    // MARK: Properties

    /// The underlying CPAlertTemplate instance.
    private(set) var _super: CPAlertTemplate?

    /// The unique identifier for the alert template.
    private(set) var elementId: String

    /// An array of title variants for the alert template.
    private var titleVariants: [String]

    /// An array of CPAlertAction instances associated with the alert template.
    private var actions: [CPAlertAction]

    /// An array of FCPAlertAction instances associated with the alert template.
    private var objcActions: [FCPAlertAction]

    // MARK: Initializer

    /// Initializes an instance of FCPAlertTemplate with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the alert template.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String else {
            fatalError("Missing required key: _elementId")
        }
        elementId = elementIdValue

        titleVariants = obj["titleVariants"] as? [String] ?? []

        objcActions = (obj["actions"] as? [[String: Any]] ?? []).map {
            FCPAlertAction(obj: $0, type: FCPAlertActionTypes.ALERT)
        }
        actions = objcActions.map {
            $0.get
        }
    }

    // MARK: Computed Property

    /// Returns the underlying CPAlertTemplate instance configured with the specified properties.
    var get: CPAlertTemplate {
        let alertTemplate = CPAlertTemplate(titleVariants: titleVariants, actions: actions)
        alertTemplate.setFCPObject(self)
        _super = alertTemplate
        return alertTemplate
    }
}

// MARK: Extensions

@available(iOS 14.0, *)
extension FCPAlertTemplate: FCPPresentTemplate {}

@available(iOS 14.0, *)
extension FCPAlertTemplate: FCPTemplate {}
