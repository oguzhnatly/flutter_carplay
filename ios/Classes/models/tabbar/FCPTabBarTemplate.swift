//
//  FCPTabBarTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPTabBarTemplate {
  private(set) var _super: CPTabBarTemplate?
  private(set) var elementId: String
  private var title: String?
  private var templates: [CPTemplate]
  private var objcTemplates: [FCPListTemplate]
  
  init(obj: [String : Any]) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as? String
    self.objcTemplates = (obj["templates"] as! Array<[String: Any]>).map {
      FCPListTemplate(obj: $0, templateType: FCPListTemplateTypes.PART_OF_GRID_TEMPLATE)
    }
    self.templates = self.objcTemplates.map {
      $0.get
    }
  }
  
  var get: CPTemplate {
    let tabBarTemplate = CPTabBarTemplate.init(templates: templates)
    tabBarTemplate.tabTitle = title
    tabBarTemplate.elementId = self.elementId
    self._super = tabBarTemplate
    return tabBarTemplate
  }
  
  public func getTemplates() -> [FCPListTemplate] {
    return objcTemplates
  }

  public func updateTemplates(templates: [FCPListTemplate]) {
    let fcpListTemplate: [String: FCPListTemplate] = Dictionary(uniqueKeysWithValues: self.objcTemplates.map { ($0.elementId, $0) })
    let cpListTemplate = Dictionary(uniqueKeysWithValues: zip(self.objcTemplates.map { $0.elementId }, self.templates))

    /// Keep Flutter CarPlay object if necessary, use new instance.
    self.objcTemplates = templates.map { template in
      if let existing = fcpListTemplate[template.elementId] {
        return existing.merge(with: template) // Merge old instance with newest to keep some data (eg: _super, handler)
      } else {
        return template // Use new instance
      }
    }

    /// Create new CarPlay template if necessary else keep currents.
    self.templates = templates.map { template in
      if let existing = cpListTemplate[template.elementId] {
        return existing // Reuse existing CP template
      } else {
        return template.get // New CP template
      }
    }
    _super?.updateTemplates(self.templates)
  }
}

@available(iOS 14.0, *)
extension FCPTabBarTemplate: FCPRootTemplate { }
