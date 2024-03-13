//
//  FCPGridButton.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

/// A wrapper class for CPGridButton with additional functionality.
@available(iOS 14.0, *)
class FCPGridButton {
    // MARK: Properties

    /// The underlying CPGridButton instance.
    private(set) var _super: CPGridButton?

    /// The unique identifier for the grid button.
    private(set) var elementId: String

    /// An array of title variants for the grid button.
    private var titleVariants: [String]

    /// The image associated with the grid button.
    private var image: UIImage

    // MARK: Initializer

    /// Initializes an instance of FCPGridButton with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the grid button.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String,
              let titleVariantsValue = obj["titleVariants"] as? [String],
              let imageValue = obj["image"] as? String
        else {
            fatalError("Missing required key: _elementId, titleVariants, or image")
        }

        elementId = elementIdValue
        titleVariants = titleVariantsValue
        image = UIImage.dynamicImage(lightImage: imageValue) ?? UIImage()
    }

    // MARK: Computed Property

    /// Returns the underlying CPGridButton instance configured with the specified properties.
    var get: CPGridButton {
        let gridButton = CPGridButton(titleVariants: titleVariants,
                                      image: image,
                                      handler: { _ in
                                          DispatchQueue.main.async {
                                              // Dispatch an event when the grid button is pressed.
                                              FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onGridButtonPressed,
                                                                               data: ["elementId": self.elementId])
                                          }
                                      })
        gridButton.isEnabled = true
        _super = gridButton
        return gridButton
    }
}
