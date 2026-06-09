//
//  FCPListTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPListTemplate {
  private(set) var _super: CPListTemplate?
  private(set) var elementId: String
  private var title: String?
  private var sections: [CPListSection] = []
  private var objcSections: [FCPListSection] = []
  private var emptyViewTitleVariants: [String] = []
  private var emptyViewSubtitleVariants: [String] = []
  private var tabTitle: String?
  private var systemIcon: String?
  private var showsTabBadge: Bool = false
  private var objcBackButton: FCPBarButton?
  private var backButton: CPBarButton?

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as? String
    self.emptyViewTitleVariants = obj["emptyViewTitleVariants"] as? [String] ?? []
    self.emptyViewSubtitleVariants = obj["emptyViewSubtitleVariants"] as? [String] ?? []
    self.tabTitle = obj["tabTitle"] as? String
    self.systemIcon = obj["systemIcon"] as? String
    self.showsTabBadge = obj["showsTabBadge"] as! Bool
    self.objcSections = (obj["sections"] as! [[String: Any]]).map {
      FCPListSection(obj: $0)
    }
    self.sections = self.objcSections.map {
      $0.get
    }
    if let backButtonData = obj["backButton"] as? [String: Any] {
      self.objcBackButton = FCPBarButton(obj: backButtonData)
      self.backButton = self.objcBackButton!.get
    }
  }

  var get: CPTemplate {
    let listTemplate = CPListTemplate.init(title: title, sections: sections)
    listTemplate.emptyViewTitleVariants = emptyViewTitleVariants
    listTemplate.emptyViewSubtitleVariants = emptyViewSubtitleVariants
    listTemplate.tabTitle = tabTitle
    listTemplate.showsTabBadge = showsTabBadge
    if let systemIcon = systemIcon {
      resolveTabIcon(systemIcon) { listTemplate.tabImage = $0 }
    }
    if let backButton = backButton {
      listTemplate.backButton = backButton
    }
    listTemplate.elementId = self.elementId
    self._super = listTemplate
    return listTemplate
  }

  public func getFCPListSections() -> [FCPListSection] {
    return objcSections
  }

  // Update templates only if structure has changed.
  public func update(with: any FCPTemplate) {
    guard let with = with as? FCPListTemplate else {
      return
    }

    let currentSections = self.objcSections
    let newSections = with.objcSections

    let hasStructureChanged: Bool = {
      if currentSections.count != newSections.count { return true }

      return zip(currentSections, newSections).contains { (current, new) in
        if current.elementId != new.elementId { return true }
        let currentItems = current.getFCPListTemplateItems()
        let newItems = new.getFCPListTemplateItems()

        if currentItems.count != newItems.count { return true }

        for (c, n) in zip(currentItems, newItems) {
          if c as AnyObject !== n as AnyObject { return true }
        }
        return false
      }
    }()

    guard hasStructureChanged else { return }

    self.updateSections(sections: newSections)
  }

  public func updateSections(sections: [FCPListSection]) {
    let fcpSectionsMap: [String: FCPListSection] = Dictionary(
      uniqueKeysWithValues: self.objcSections.map { ($0.elementId, $0) })
    let cpSectionsMap = Dictionary(
      uniqueKeysWithValues: zip(self.objcSections.map { $0.elementId }, self.sections))

    /// CPListSection didn't provide any way to update items
    self.objcSections = sections
    self.sections = sections.map { section in
      return section.get
    }
    _super?.updateSections(self.sections)
  }
}

@available(iOS 14.0, *)
extension FCPListTemplate: FCPTemplate {}
