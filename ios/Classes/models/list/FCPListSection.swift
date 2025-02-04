//
//  FCPListSection.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

/// A wrapper class for CPListSection with additional functionality.
@available(iOS 14.0, *)
class FCPListSection {
    // MARK: Properties

    /// The underlying CPListSection instance.
    private(set) var _super: CPListSection?

    /// The unique identifier for the list section.
    private(set) var elementId: String

    /// The header text for the list section (optional).
    private var header: String?

    /// An array of CPListTemplateItem instances associated with the list section.
    private var items: [CPListTemplateItem]

    /// An array of FCPListItem instances associated with the list section.
    private var objcItems: [FCPListItem]

    // MARK: Initializer

    /// Initializes an instance of FCPListSection with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the list section.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String else {
            fatalError("Missing required keys in dictionary for FCPListSection initialization.")
        }

        elementId = elementIdValue
        header = obj["header"] as? String
        objcItems = (obj["items"] as? [[String: Any]] ?? []).map {
            FCPListItem(obj: $0)
        }
        items = objcItems.map {
            $0.get
        }
    }

    // MARK: Computed Property

    /// Returns the underlying CPListSection instance configured with the specified properties.
    var get: CPListSection {
        let listSection = CPListSection(items: items, header: header, sectionIndexTitle: header)
        _super = listSection
        return listSection
    }

    // MARK: Public Methods

    /// Retrieves an array of FCPListItem instances associated with the list section.
    ///
    /// - Returns: An array of FCPListItem instances.
    public func getItems() -> [FCPListItem] {
        return objcItems
    }
}
