//
//  FCPBarButton.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 25.08.2021.
//

import CarPlay

/// A wrapper class for CPBarButton with additional functionality.
@available(iOS 14.0, *)
class FCPBarButton {
    // MARK: Properties

    /// The underlying CPBarButton instance.
    private(set) var _super: CPBarButton?

    /// The unique identifier for the bar button.
    private(set) var elementId: String

    /// The image associated with the bar button (optional).
    private var image: UIImage?

    /// The title associated with the bar button (optional).
    private var title: String?

    /// The style of the bar button.
    private var style: CPBarButtonStyle

    /// The enabled state of the bar button.
    private var isEnabled: Bool = true

    // MARK: Initializer

    /// Initializes an instance of FCPBarButton with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the bar button.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String else {
            fatalError("Missing required key: _elementId")
        }
        elementId = elementIdValue

        title = obj["title"] as? String

        if let imageName = obj["image"] as? String {
            image = UIImage.dynamicImage(lightImage: imageName)
        }

        isEnabled = obj["isEnabled"] as? Bool ?? true

        style = (obj["style"] as? String == "none") ? .none : .rounded
    }

    // MARK: Computed Property

    /// Returns the underlying CPBarButton instance configured with the specified properties.
    var get: CPBarButton {
        var barButton: CPBarButton

        if let barTitle = title {
            barButton = CPBarButton(title: barTitle, handler: { _ in
                DispatchQueue.main.async {
                    // Dispatch an event when the bar button is pressed.
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onBarButtonPressed, data: ["elementId": self.elementId])
                }
            })
        } else if let barImage = image {
            barButton = CPBarButton(image: barImage, handler: { _ in
                DispatchQueue.main.async {
                    // Dispatch an event when the bar button is pressed.
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onBarButtonPressed, data: ["elementId": self.elementId])
                }
            })
        } else {
            barButton = CPBarButton(title: "", handler: { _ in })
        }

        barButton.isEnabled = isEnabled
        barButton.buttonStyle = style
        _super = barButton
        return barButton
    }
}
