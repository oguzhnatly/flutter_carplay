//
//  FCPSearchTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

/// A custom template for performing searches on CarPlay.
@available(iOS 14.0, *)
class FCPSearchTemplate: NSObject {
    // MARK: Properties

    /// The underlying FCPSearchTemplate instance.
    private(set) var _super: CPSearchTemplate?

    /// The unique identifier for the search template.
    private(set) var elementId: String

    /// A closure that is called when the search text is updated, providing search results.
    private var searchPerformedHandler: (([CPListItem]) -> Void)?

    /// A debounce object for optimizing search events.
    private let _debounce = Debounce(delay: 0.5)

    // MARK: Initialization

    /// Initializes a new instance of `FCPSearchTemplate` with the specified parameters.
    ///
    /// - Parameter obj: A dictionary containing the properties of the search template.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String else {
            fatalError("Missing required key: _elementId")
        }

        elementId = elementIdValue
    }

    // MARK: Methods

    /// Returns a `CPSearchTemplate` object representing the search template.
    ///
    /// - Returns: A `CPSearchTemplate` object.
    var get: CPSearchTemplate {
        let template = CPSearchTemplate()
        template.setFCPObject(self)
        template.delegate = self
        _super = template
        return template
    }
}

@available(iOS 14.0, *)
extension FCPSearchTemplate: FCPTemplate {}

extension FCPSearchTemplate: CPSearchTemplateDelegate {
    func searchTemplate(_: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        // Debounce search events.
        _debounce.debounce { [weak self] in
            guard let self = self else { return }

            self.searchPerformedHandler = completionHandler
            FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onSearchTextUpdated,
                                             data: ["elementId": self.elementId, "query": searchText])
        }
    }

    func searchTemplate(_: CPSearchTemplate, selectedResult: CPListItem, completionHandler: @escaping () -> Void) {
        if let userInfo = selectedResult.userInfo as? [String: Any],
           let elementId = userInfo["elementId"] as? String
        {
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onSearchResultSelected,
                                                 data: ["elementId": self.elementId,
                                                        "itemElementId": elementId])
                completionHandler()
            }
        } else {
            completionHandler()
        }
    }

    func searchPerformed(_ searchResults: [FCPListItem]) {
        let results = searchResults.map {
            let obj = $0.get
            obj.userInfo = ["elementId": $0.elementId]
            return obj
        }
        searchPerformedHandler?(results)
        searchPerformedHandler = nil
    }
}
