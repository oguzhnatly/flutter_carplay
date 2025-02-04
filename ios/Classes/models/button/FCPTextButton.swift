//
//  FCPTextButton.swift
//  Runner
//
//  Created by Olaf Schneider on 17.02.22.
//

import CarPlay

/// A wrapper class for CPTextButton with additional functionality.
@available(iOS 14.0, *)
class FCPTextButton {
    // MARK: Properties

    /// The underlying CPTextButton instance.
    private(set) var _super: CPTextButton?

    /// The unique identifier for the text button.
    private(set) var elementId: String

    /// The title associated with the text button.
    private var title: String

    /// The style of the text button.
    private var style: CPTextButtonStyle

    // MARK: Initializer

    /// Initializes an instance of FCPTextButton with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the text button.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String,
              let titleValue = obj["title"] as? String
        else {
            fatalError("Missing required key: _elementId or title")
        }

        elementId = elementIdValue
        title = titleValue

        let styleString = obj["style"] as? String ?? "normal"

        switch styleString {
        case "normal":
            style = .normal
        case "cancel":
            style = .cancel
        case "confirm":
            style = .confirm
        default:
            style = .normal
        }
    }

    // MARK: Computed Property

    /// Returns the underlying CPTextButton instance configured with the specified properties.
    var get: CPTextButton {
        let textButton = CPTextButton(title: title, textStyle: style, handler: { _ in
            DispatchQueue.main.async {
                // Dispatch an event when the text button is pressed.
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onTextButtonPressed, data: ["elementId": self.elementId])
            }
        })
        _super = textButton
        return textButton
    }
}
