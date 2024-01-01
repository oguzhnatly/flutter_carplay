//
//  FCPInformationItem.swift
//  flutter_carplay
//
//  Created by Olaf Schneider on 17.02.22.
//

import CarPlay

/// A wrapper class for CPInformationItem with additional functionality.
@available(iOS 14.0, *)
class FCPInformationItem {
    // MARK: Properties

    /// The underlying CPInformationItem instance.
    private(set) var _super: CPInformationItem?

    /// The unique identifier for the information item.
    private(set) var elementId: String

    /// The title of the information item (optional).
    private var title: String?

    /// The detail text of the information item (optional).
    private var detail: String?

    // MARK: Initializer

    /// Initializes an instance of FCPInformationItem with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the information item.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String else {
            fatalError("Missing required key: _elementId")
        }

        elementId = elementIdValue
        title = obj["title"] as? String
        detail = obj["detail"] as? String
    }

    // MARK: Computed Property

    /// Returns the underlying CPInformationItem instance configured with the specified properties.
    var get: CPInformationItem {
        let informationItem = CPInformationItem(title: title, detail: detail)
        _super = informationItem
        return informationItem
    }
}
