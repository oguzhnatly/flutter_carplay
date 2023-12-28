//
//  FCPSearchTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPSearchTemplate: NSObject {
	private(set) var _super: CPSearchTemplate?
	private(set) var elementId: String
	private var searchPerformedHandler: (([CPListItem]) -> Void)?

	init(obj: [String: Any]) {
		elementId = obj["_elementId"] as! String
	}

	var get: CPSearchTemplate {
		let template = CPSearchTemplate()
		template.delegate = self
		_super = template
		return template
	}
}

@available(iOS 14.0, *)
extension FCPSearchTemplate: FCPTemplate {}

extension FCPSearchTemplate: CPSearchTemplateDelegate {
	func searchTemplate(_: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
		searchPerformedHandler = completionHandler
		DispatchQueue.main.async {
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
		guard searchPerformedHandler != nil else {
			return
		}

		let results = searchResults.map {
			let obj = $0.get
			obj.userInfo = ["elementId": $0.elementId]
			return obj
		}
		searchPerformedHandler!(results)
		searchPerformedHandler = nil
	}
}
