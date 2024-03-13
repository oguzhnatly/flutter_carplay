//
//  FCPMapButton.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 25.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPMapButton {
    /// The underlying CPMapButton instance.
    private(set) var _super: CPMapButton?

    /// The unique identifier for the map button.
    private(set) var elementId: String

    /// A Boolean value indicating whether the map button is enabled.
    private var isEnabled: Bool = true

    /// A Boolean value indicating whether the map button is hidden.
    private var isHidden: Bool = false

    /// The image associated with the map button.
    private var image: UIImage?

    /// The focused image associated with the map button.
    private var focusedImage: UIImage?

    /// Initializes an instance of FCPMapButton with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the map button.
    init(obj: [String: Any]) {
        guard let elementId = obj["_elementId"] as? String else {
            fatalError("Missing required keys in dictionary for FCPMapButton initialization..")
        }

        self.elementId = elementId
        isEnabled = obj["isEnabled"] as? Bool ?? true
        isHidden = obj["isHidden"] as? Bool ?? false

        image = UIImage.dynamicImage(lightImage: obj["image"] as? String,
                                     darkImage: obj["darkImage"] as? String)

        if let tintColor = obj["tintColor"] as? Int {
            image = image?.withColor(UIColor(argb: tintColor))
        }

        if let focusedImage = obj["focusedImage"] as? String {
            self.focusedImage = UIImage.dynamicImage(lightImage: focusedImage)
        }
    }

    /// Returns the underlying CPMapButton instance configured with the specified properties.
    var get: CPMapButton {
        let mapButton = CPMapButton { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onMapButtonPressed, data: ["elementId": self.elementId])
            }
        }
        mapButton.isHidden = isHidden
        mapButton.isEnabled = isEnabled
        mapButton.focusedImage = focusedImage
        mapButton.image = image

        _super = mapButton
        return mapButton
    }
}
