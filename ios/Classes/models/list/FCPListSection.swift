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
  private var objcItems: [FCPListItem]
  private var sectionIndexEnabled: Bool

  init(obj: [String : Any], sectionIndexEnabled: Bool = true) {
    self.elementId = obj["_elementId"] as! String
    self.header = obj["header"] as? String
    self.sectionIndexEnabled = sectionIndexEnabled
    self.objcItems = (obj["items"] as! Array<[String : Any]>).map {
      FCPListItem(obj: $0)
    }
    self.items = self.objcItems.map {
      $0.get
    }
  }

  var get: CPListSection {
    let indexTitle = sectionIndexEnabled ? header : nil
    let listSection = CPListSection.init(items: items, header: header, sectionIndexTitle: indexTitle)
    self._super = listSection
    return listSection
  }
  
  public func getItems() -> [FCPListItem] {
    return objcItems 
  }

  public func merge(with: FCPListSection) -> FCPListSection {
    let copy = with
    self.updateItems(items: copy.objcItems)
    copy._super = self._super
    copy.objcItems = self.objcItems;
    copy.items = self.items;
    return copy;
  }

  public func updateItems(items: [FCPListItem]) {
    let fcpListTemplateItem: [String: FCPListItem] = Dictionary(uniqueKeysWithValues: self.objcItems.map { ($0.elementId, $0) })
    let cpListTemplateItem = Dictionary(uniqueKeysWithValues: zip(self.objcItems.map { $0.elementId }, self.items))

    /// Keep Flutter CarPlay object if necessary, use new instance.
    self.objcItems = items.map { item in
      if let existing = fcpListTemplateItem[item.elementId] {
        return existing.merge(with: item) // Merge old instance with newest to keep some data (eg: completeHandler)
      } else {
        return item // Use new instance
      }
    }
    self.items = items.map { item in
      if let existing = cpListTemplateItem[item.elementId] {
        return existing // Reuse existing CP template
      } else {
        return item.get // New CP template
      }
    }
  }
}
