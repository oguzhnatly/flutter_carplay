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
  
  init(obj: [String : Any], templateType: FCPListTemplateTypes) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as? String
    self.systemIcon = obj["systemIcon"] as! String
    self.emptyViewTitleVariants = obj["emptyViewTitleVariants"] as? [String] ?? []
    self.emptyViewSubtitleVariants = obj["emptyViewSubtitleVariants"] as? [String] ?? []
    self.showsTabBadge = obj["showsTabBadge"] as! Bool
    self.templateType = templateType 
    self.objcSections = (obj["sections"] as! Array<[String : Any]>).map {
      FCPListSection(obj: $0)
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
  
  var get: CPListTemplate {
    let listTemplate = CPListTemplate.init(title: title, sections: sections)
    listTemplate.emptyViewTitleVariants = emptyViewTitleVariants
    listTemplate.emptyViewSubtitleVariants = emptyViewSubtitleVariants
    listTemplate.showsTabBadge = showsTabBadge
    listTemplate.tabImage = UIImage(systemName: systemIcon)
    if (templateType == FCPListTemplateTypes.DEFAULT) {
      listTemplate.backButton = self.backButton
    }
    self._super = listTemplate
    return listTemplate
  }
  
  public func getSections() -> [FCPListSection] {
    return objcSections
  }
}

@available(iOS 14.0, *)
extension FCPListTemplate: FCPRootTemplate { }
