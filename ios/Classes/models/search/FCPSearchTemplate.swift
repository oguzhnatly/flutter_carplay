//
// FCPSearchTemplate.swift
// flutter_carplay
//
// Created by Pradip Sutariya on 29.04.2024.
// Copyright © 2024 Aubergine Solutions Pvt. Ltd. All rights reserved.
//

import CarPlay
import Foundation

@available(iOS 14.0, *)
class FCPSearchTemplate: NSObject {
    private(set) var _super: CPSearchTemplate?
    private(set) var elementId: String
    private var searchCompletionHandler: (([CPListItem]) -> Void)?
    private var debouncer: Debouncer
    private var shouldSearchAsType: Bool
    private var searchQuery: String = ""

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        debouncer = Debouncer(delay: obj["debounce"] as? Double ?? 0.5)
        shouldSearchAsType = obj["shouldSearchAsType"] as? Bool ?? false
    }

    var get: CPSearchTemplate {
        let template = CPSearchTemplate()
        template.userInfo = ["FCPObject": self]
        template.delegate = self
        _super = template
        return template
    }
}

extension FCPSearchTemplate: CPSearchTemplateDelegate {
    func searchTemplate(_: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        debouncer.debounce { [weak self] in
            guard let self = self else { return }
            self.searchQuery = searchText
            self.searchCompletionHandler = completionHandler
            if self.shouldSearchAsType || searchText.isEmpty {
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onSearchTextUpdated,
                                                 data: ["elementId": self.elementId, "query": self.searchQuery])
            }
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

    func searchTemplateSearchButtonPressed(_: CPSearchTemplate) {
        if !shouldSearchAsType {
            FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onSearchTextUpdated,
                                             data: ["elementId": elementId,
                                                    "query": searchQuery])
        }
    }

    func searchCompleted(_ searchResults: [FCPListItem]) {
        let results = searchResults.map {
            let obj = $0.get
            obj.userInfo = ["elementId": $0.elementId]
            return obj
        }
        searchCompletionHandler?(results)
        searchCompletionHandler = nil
    }
}
