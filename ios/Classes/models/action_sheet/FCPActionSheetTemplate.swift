//
//  FCPActionSheetTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 25.08.2021.
//

import CarPlay

/// A wrapper class for CPActionSheetTemplate with additional functionality.
@available(iOS 14.0, *)
class FCPActionSheetTemplate {
    // MARK: Properties

    /// The underlying CPActionSheetTemplate instance.
    private(set) var _super: CPActionSheetTemplate?

    /// The unique identifier for the action sheet template.
    private(set) var elementId: String

    /// The title of the action sheet template (optional).
    private var title: String?

    /// The message of the action sheet template (optional).
    private var message: String?

    /// An array of CPAlertAction instances associated with the action sheet template.
    private var actions: [CPAlertAction]

    /// An array of FCPAlertAction instances associated with the action sheet template.
    private var objcActions: [FCPAlertAction]

    // MARK: Initializer

    /// Initializes an instance of FCPActionSheetTemplate with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the action sheet template.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String else {
            fatalError("Missing required key: _elementId")
        }

        elementId = elementIdValue

        title = obj["title"] as? String
        message = obj["message"] as? String

        if let actionsData = obj["actions"] as? [[String: Any]] {
            objcActions = actionsData.map {
                FCPAlertAction(obj: $0, type: FCPAlertActionTypes.ACTION_SHEET)
            }
            actions = objcActions.map { $0.get }
        } else {
            // Handle the absence of "actions" as needed.
            // You might want to set actions to an empty array or provide a default value.
            actions = []
            objcActions = []
        }
    }

    // MARK: Computed Property

    /// Returns the underlying CPActionSheetTemplate instance configured with the specified properties.
    var get: CPActionSheetTemplate {
        let actionSheetTemplate = CPActionSheetTemplate(title: title, message: message, actions: actions)
        actionSheetTemplate.setFCPObject(self)
        _super = actionSheetTemplate
        return actionSheetTemplate
    }
}

// MARK: Extensions

@available(iOS 14.0, *)
extension FCPActionSheetTemplate: FCPPresentTemplate {}

@available(iOS 14.0, *)
extension FCPActionSheetTemplate: FCPTemplate {}
