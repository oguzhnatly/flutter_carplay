//
// FCPDashboardButton.swift
// flutter_carplay
//
// Created by Pradip Sutariya on 10/04/24.
//

import CarPlay
import Foundation

@available(iOS 14.0, *)
class FCPDashboardButton {
    /// The underlying CPDashboardButton instance.
    private(set) var _super: CPDashboardButton?

    /// The unique identifier for the map button.
    private(set) var elementId: String

    /// Title variants for the dashboard button.
    private var titleVariants: [String]

    /// Subtitle variants for the dashboard button.
    private var subtitleVariants: [String]

    /// The image associated with the dashboard button.
    private var image: UIImage?

    /// Initializes an instance of FCPMapButton with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the map button.
    init(obj: [String: Any]) {
        guard let elementId = obj["_elementId"] as? String else {
            fatalError("Missing required keys in dictionary for FCPMapButton initialization..")
        }

        self.elementId = elementId

        if let titleVariants = obj["titleVariants"] as? [String] {
            self.titleVariants = titleVariants
        } else {
            titleVariants = []
        }

        if let subtitleVariants = obj["subtitleVariants"] as? [String] {
            self.subtitleVariants = subtitleVariants
        } else {
            subtitleVariants = []
        }

        image = UIImage.dynamicImage(lightImage: obj["image"] as? String,
                                     darkImage: obj["darkImage"] as? String)
    }

    /// Returns the underlying CPDashboardButton instance configured with the specified properties.
    var get: CPDashboardButton {
        let dashboardButton = CPDashboardButton(titleVariants: titleVariants, subtitleVariants: subtitleVariants, image: image!) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onDashboardButtonPressed, data: ["elementId": self.elementId])
            }
        }
        _super = dashboardButton
        return dashboardButton
    }
}
