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
  private var tabTitle: String?
  private var systemIcon: String?
  private var showsTabBadge: Bool = false
  private var templates: [CPTemplate]
  private var objcTemplates: [FCPTemplate]

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.tabTitle = obj["tabTitle"] as? String
    self.systemIcon = obj["systemIcon"] as? String
    self.showsTabBadge = obj["showsTabBadge"] as! Bool
    self.objcTemplates = (obj["templates"] as! [[String: Any]]).map {
      FCPTabBarTemplate.parseTemplate(obj: $0)
    }
    self.templates = self.objcTemplates.map { $0.get }
  }

  public static func parseTemplate(obj: [String: Any]) -> FCPTemplate {
    guard let runtimeType = obj["runtimeType"] as? String else {
      fatalError("FCPTabBarTemplate.parseTemplates: Missing runtimeType in item")
    }

    if runtimeType == "FCPListTemplate" {
      return FCPListTemplate(obj: obj)
    } else if runtimeType == "FCPPointOfInterestTemplate" {
      return FCPPointOfInterestTemplate(obj: obj)
    } else if runtimeType == "FCPGridTemplate" {
      return FCPGridTemplate(obj: obj)
    } else if runtimeType == "FCPInformationTemplate" {
      return FCPInformationTemplate(obj: obj)
    } else {
      fatalError("FCPTabBarTemplate.parseTemplates: Unknown template type: \(runtimeType)")
    }
  }

  var get: CPTemplate {
    let tabBarTemplate = CPTabBarTemplate.init(templates: templates)
    tabBarTemplate.tabTitle = tabTitle
    tabBarTemplate.showsTabBadge = showsTabBadge
    if let systemIcon = systemIcon {
      tabBarTemplate.tabImage = UIImage(systemName: systemIcon)
    }

    tabBarTemplate.elementId = self.elementId
    self._super = tabBarTemplate
    return tabBarTemplate
  }

  public func getFCPTemplates() -> [FCPTemplate] {
    return objcTemplates
  }

  // Update templates only if structure has changed.
  public func update(with: any FCPTemplate) {
    guard let with = with as? FCPTabBarTemplate else {
      return
    }

    let currentTemplates = self.objcTemplates
    let newTemplates = with.objcTemplates

    let hasStructureChanged: Bool = {
      if currentTemplates.count != newTemplates.count { return true }

      return zip(currentTemplates, newTemplates).contains { (current, new) in
        current.elementId != new.elementId
      }
    }()

    guard hasStructureChanged else { return }

    self.updateTemplates(templates: newTemplates)
  }

  public func updateTemplates(templates: [FCPTemplate]) {
    let existingTemplatesById: [String: FCPTemplate] = Dictionary(
      uniqueKeysWithValues: self.objcTemplates.map { ($0.elementId, $0) })
    let existingCPTemplatesById = Dictionary(
      uniqueKeysWithValues: zip(self.objcTemplates.map { $0.elementId }, self.templates))

    /// Update actual template or create new one if missing
    self.objcTemplates = templates.map { template in
      if let existing = existingTemplatesById[template.elementId] {
        existing.update(with: template)
        return existing // Reuse existing FCP template with updated content
      } else {
        return template  // Use new instance
      }
    }
    self.templates = templates.map { template in
      if let existing = existingCPTemplatesById[template.elementId] {
        return existing  // Reuse existing CP template
      } else {
        return template.get  // New CP template
      }
    }
    _super?.updateTemplates(self.templates)
  }
}

@available(iOS 14.0, *)
extension FCPTabBarTemplate: FCPTemplate {}
