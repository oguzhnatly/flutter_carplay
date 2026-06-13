//
//  FCPListSection.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPListSection {
  private(set) var _super: CPListSection?
  private(set) var elementId: String
  private var header: String?
  private var items: [CPListTemplateItem]
  private var objcItems: [FCPListTemplateItem]
  private var sectionIndexEnabled: Bool

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.header = obj["header"] as? String
    self.sectionIndexEnabled = obj["sectionIndexEnabled"] as? Bool ?? true
    self.objcItems = (obj["items"] as! [[String: Any]]).map { dict -> FCPListTemplateItem in
      guard let runtimeType = dict["runtimeType"] as? String else {
        fatalError("FCPListSection.init: Missing runtimeType in item")
      }

      if runtimeType == "FCPListImageRowItem" {
        return FCPListImageRowItem(obj: dict) as FCPListTemplateItem
      } else if runtimeType == "FCPListItem" {
        return FCPListItem(obj: dict) as FCPListTemplateItem
      } else {
        fatalError("FCPListSection.init: Unknown item runtimeType: \(runtimeType)")
      }
    }
    self.items = self.objcItems.map {
      $0.get
    }
  }

  var get: CPListSection {
    let sectionIndexTitle = sectionIndexEnabled ? header : nil

    let listSection = CPListSection.init(
      items: items, header: header, sectionIndexTitle: sectionIndexTitle)

    self._super = listSection
    return listSection
  }

  public func getFCPListTemplateItems() -> [FCPListTemplateItem] {
    return objcItems
  }
}
