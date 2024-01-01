//
//  FCPGridTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

/// A wrapper class for CPGridTemplate with additional functionality.
@available(iOS 14.0, *)
class FCPGridTemplate {
    // MARK: Properties

    /// The underlying CPGridTemplate instance.
    private(set) var _super: CPGridTemplate?

    /// The unique identifier for the grid template.
    private(set) var elementId: String

    /// The title of the grid template.
    private var title: String

    /// An array of CPGridButton instances associated with the grid template.
    private var buttons: [CPGridButton]

    /// An array of FCPGridButton instances associated with the grid template.
    private var objcButtons: [FCPGridButton]

    // MARK: Initializer

    /// Initializes an instance of FCPGridTemplate with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the grid template.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String,
              let titleValue = obj["title"] as? String,
              let buttonsData = obj["buttons"] as? [[String: Any]]
        else {
            fatalError("Missing required key: _elementId, title, or buttons")
        }

        elementId = elementIdValue
        title = titleValue
        objcButtons = buttonsData.map {
            FCPGridButton(obj: $0)
        }
        buttons = objcButtons.map {
            $0.get
        }
    }

    // MARK: Computed Property

    /// Returns the underlying CPGridTemplate instance configured with the specified properties.
    var get: CPGridTemplate {
        let gridTemplate = CPGridTemplate(title: title, gridButtons: buttons)
        gridTemplate.setFCPObject(self)
        _super = gridTemplate
        return gridTemplate
    }
}

// MARK: Extensions

@available(iOS 14.0, *)
extension FCPGridTemplate: FCPRootTemplate {}

@available(iOS 14.0, *)
extension FCPGridTemplate: FCPTemplate {}
