//
//  FCPSearchTemplate.swift
//  flutter_carplay
//

import CarPlay

@available(iOS 14.0, *)
class FCPSearchTemplate: NSObject, CPSearchTemplateDelegate {
  private(set) var _super: CPSearchTemplate?
  private(set) var elementId: String
  private var searchCompletionHandler: (([CPListItem]) -> Void)?
  private var selectedCompletionHandler: (() -> Void)?
  private var currentResultItems: [FCPListItem] = []

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
  }

  var get: CPTemplate {
    let searchTemplate = CPSearchTemplate()
    searchTemplate.delegate = self
    searchTemplate.elementId = self.elementId
    self._super = searchTemplate
    return searchTemplate
  }

  func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
    self.searchCompletionHandler = completionHandler
    DispatchQueue.main.async {
      FCPStreamHandlerPlugin.sendEvent(
        type: FCPChannelTypes.onSearchTextUpdated,
        data: ["elementId": self.elementId, "searchText": searchText]
      )
    }
  }

  func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
    self.selectedCompletionHandler = completionHandler
    var selectedElementId = ""
    for fcpItem in currentResultItems {
      if fcpItem._super === item {
        selectedElementId = fcpItem.elementId
        break
      }
    }
    DispatchQueue.main.async {
      FCPStreamHandlerPlugin.sendEvent(
        type: FCPChannelTypes.onSearchResultSelected,
        data: ["elementId": self.elementId, "itemElementId": selectedElementId]
      )
    }
  }

  func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {
    DispatchQueue.main.async {
      FCPStreamHandlerPlugin.sendEvent(
        type: FCPChannelTypes.onSearchButtonPressed,
        data: ["elementId": self.elementId]
      )
    }
  }

  public func updateSearchResults(items: [FCPListItem]) {
    self.currentResultItems = items
    let cpItems = items.compactMap { $0.get as? CPListItem }
    self.searchCompletionHandler?(cpItems)
    self.searchCompletionHandler = nil
  }

  public func completeSelectedResult() {
    self.selectedCompletionHandler?()
    self.selectedCompletionHandler = nil
  }

  public func getCurrentResultItems() -> [FCPListItem] {
    return currentResultItems
  }
}

@available(iOS 14.0, *)
extension FCPSearchTemplate: FCPTemplate {
  public func update(with template: any FCPTemplate) {}
}
