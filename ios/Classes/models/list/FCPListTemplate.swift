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
  private var systemIcon: String
  private var sections: [CPListSection] = []
  private var objcSections: [FCPListSection] = []
  private var emptyViewTitleVariants: [String] = []
  private var emptyViewSubtitleVariants: [String] = []
  private var showsTabBadge: Bool = false
  private var templateType: FCPListTemplateTypes
  private var objcBackButton: FCPBarButton?
  private var backButton: CPBarButton?
  private var sectionIndexEnabled: Bool = true

  init(obj: [String : Any], templateType: FCPListTemplateTypes) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as? String
    self.systemIcon = obj["systemIcon"] as! String
    self.emptyViewTitleVariants = obj["emptyViewTitleVariants"] as? [String] ?? []
    self.emptyViewSubtitleVariants = obj["emptyViewSubtitleVariants"] as? [String] ?? []
    self.showsTabBadge = obj["showsTabBadge"] as! Bool
    self.sectionIndexEnabled = obj["sectionIndexEnabled"] as? Bool ?? true
    self.templateType = templateType
    self.objcSections = (obj["sections"] as! Array<[String : Any]>).map {
      FCPListSection(obj: $0, sectionIndexEnabled: self.sectionIndexEnabled)
    }
    self.sections = self.objcSections.map {
      $0.get
    }
    let backButtonData = obj["backButton"] as? [String : Any]
    if backButtonData != nil {
      self.objcBackButton = FCPBarButton(obj: backButtonData!)
      self.backButton = self.objcBackButton?.get
    }
  }
  
  var get: CPTemplate {
    let listTemplate = CPListTemplate.init(title: title, sections: sections)
    listTemplate.emptyViewTitleVariants = emptyViewTitleVariants
    listTemplate.emptyViewSubtitleVariants = emptyViewSubtitleVariants
    listTemplate.showsTabBadge = showsTabBadge
    listTemplate.tabImage = UIImage(systemName: systemIcon)
    if (templateType == FCPListTemplateTypes.DEFAULT) {
      listTemplate.backButton = self.backButton
    }
    listTemplate.elementId = self.elementId
    self._super = listTemplate
    return listTemplate
  }
  
  public func getSections() -> [FCPListSection] {
    return objcSections
  }

  public func merge(with: FCPListTemplate) -> FCPListTemplate {
    let copy = with
    self.updateSections(sections: copy.objcSections)
    copy._super = self._super
    copy.objcSections = self.objcSections
    copy.sections = self.sections
    return copy;
  }

  public func updateSections(sections: [FCPListSection]) {
    let fcpSectionsMap: [String: FCPListSection] = Dictionary(uniqueKeysWithValues: self.objcSections.map { ($0.elementId, $0) })
    let cpSectionsMap = Dictionary(uniqueKeysWithValues: zip(self.objcSections.map { $0.elementId }, self.sections))

    /// Keep Flutter CarPlay object if necessary, use new instance.
    self.objcSections = sections.map { section in
      if let existing = fcpSectionsMap[section.elementId] {
        return existing.merge(with: section) // Merge old instance with newest to keep some data (eg: completeHandler)
      } else {
        return section // Use new instance
      }
    }
    self.sections = sections.map { section in
      if let existing = cpSectionsMap[section.elementId] {
        return existing // Reuse existing CP template
      } else {
        return section.get // New CP template
      }
    }

    _super?.updateSections(self.sections)
  }
}

@available(iOS 14.0, *)
extension FCPListTemplate: FCPRootTemplate { }
