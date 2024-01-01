//
//  FCPAlertAction.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
/// Wrapper class for CPAlertAction with additional functionality.
class FCPAlertAction {
    // MARK: Properties

    /// The underlying CPAlertAction instance.
    private(set) var _super: CPAlertAction?

    /// The unique identifier for the alert action.
    private(set) var elementId: String

    /// The title of the alert action.
    private var title: String

    /// The style of the alert action.
    private var style: CPAlertAction.Style

    /// The type of handler associated with the alert action.
    private var handlerType: FCPAlertActionTypes

    // MARK: Initializer

    /// Initializes an instance of FCPAlertAction with the provided parameters.
    ///
    /// - Parameters:
    ///   - obj: A dictionary containing information about the alert action.
    ///   - type: The type of handler associated with the alert action.
    init(obj: [String: Any], type: FCPAlertActionTypes) {
        guard let elementIdValue = obj["_elementId"] as? String else {
            fatalError("Missing required key: _elementId")
        }
        elementId = elementIdValue

        guard let titleValue = obj["title"] as? String else {
            fatalError("Missing required key: title")
        }
        title = titleValue

        let styleString = obj["style"] as? String ?? ""

        switch styleString.lowercased() {
        case "destructive":
            style = .destructive
        case "cancel":
            style = .cancel
        default:
            style = .default
        }

        handlerType = type
    }

    // MARK: Computed Property

    /// Returns the underlying CPAlertAction instance configured with the specified properties.
    var get: CPAlertAction {
        let alertAction = CPAlertAction(title: title, style: style, handler: { _ in
            DispatchQueue.main.async {
                // Dispatch an event when the alert action is pressed.
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onAlertActionPressed, data: ["elementId": self.elementId])
            }
        })
        _super = alertAction
        return alertAction
    }
}
