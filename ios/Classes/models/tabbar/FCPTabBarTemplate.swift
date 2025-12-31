//
//  FCPTabBarTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
protocol FCPTabBarChildTemplate {
    var elementId: String { get }
    var get: CPTemplate { get }
}

@available(iOS 14.0, *)
extension FCPListTemplate: FCPTabBarChildTemplate { }

@available(iOS 14.0, *)
extension FCPPointOfInterestTemplate: FCPTabBarChildTemplate { }

@available(iOS 14.0, *)
extension FCPGridTemplate: FCPTabBarChildTemplate { }

@available(iOS 14.0, *)
extension FCPInformationTemplate: FCPTabBarChildTemplate { }

@available(iOS 14.0, *)
protocol TemplateFactory {
    func create(from data: [String: Any]) -> FCPTabBarChildTemplate?
}

@available(iOS 14.0, *)
struct FCPListTemplateFactory: TemplateFactory {
    func create(from data: [String: Any]) -> FCPTabBarChildTemplate? {
        return FCPListTemplate(obj: data, templateType: FCPListTemplateTypes.PART_OF_GRID_TEMPLATE)
    }
}

@available(iOS 14.0, *)
struct FCPPointOfInterestTemplateFactory: TemplateFactory {
    func create(from data: [String: Any]) -> FCPTabBarChildTemplate? {
        return FCPPointOfInterestTemplate(obj: data)
    }
}

@available(iOS 14.0, *)
struct FCPGridTemplateFactory: TemplateFactory {
    func create(from data: [String: Any]) -> FCPTabBarChildTemplate? {
        return FCPGridTemplate(obj: data)
    }
}

@available(iOS 14.0, *)
struct FCPInformationTemplateFactory: TemplateFactory {
    func create(from data: [String: Any]) -> FCPTabBarChildTemplate? {
        return FCPInformationTemplate(obj: data)
    }
}

@available(iOS 14.0, *)
struct TemplateFactoryMapper {
    private static let factories: [String: TemplateFactory] = [
        String(describing: FCPListTemplate.self): FCPListTemplateFactory(),
        String(describing: FCPPointOfInterestTemplate.self): FCPPointOfInterestTemplateFactory(),
        String(describing: FCPGridTemplate.self): FCPGridTemplateFactory(),
        String(describing: FCPInformationTemplate.self): FCPInformationTemplateFactory(),
    ]
    
    private static let defaultFactory: TemplateFactory = FCPListTemplateFactory()
    
    static func getFactory(for typeKey: String) -> TemplateFactory {
        return factories[typeKey] ?? defaultFactory
    }
}

@available(iOS 14.0, *)
class FCPTabBarTemplate {
  private(set) var _super: CPTabBarTemplate?
  private(set) var elementId: String
  private var title: String?
  private var templates: [CPTemplate]
  private var objcTemplates: [FCPTabBarChildTemplate]
  
  init(obj: [String : Any]) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as? String
    self.objcTemplates = FCPTabBarTemplate.parseTemplates(obj["templates"] as! Array<[String: Any]>)
    self.templates = self.objcTemplates.map { $0.get }
  }
   

  private static func parseTemplates(_ templatesData: Array<[String: Any]>) -> [FCPTabBarChildTemplate] {
    return templatesData.compactMap { data in
      let typeKey = data["runtimeType"] as? String ?? String(describing: FCPListTemplate.self)
      return TemplateFactoryMapper.getFactory(for: typeKey).create(from: data)
    }
  }
  
  var get: CPTemplate {
    let tabBarTemplate = CPTabBarTemplate.init(templates: templates)
    tabBarTemplate.tabTitle = title
    tabBarTemplate.elementId = self.elementId
    self._super = tabBarTemplate
    return tabBarTemplate
  }
  
  public func getTemplates() -> [FCPTabBarChildTemplate] {
    return objcTemplates
  }

  public func updateTemplates(newTemplatesData: Array<[String: Any]>) {
    let existingTemplatesById: [String: FCPTabBarChildTemplate] = Dictionary(uniqueKeysWithValues: self.objcTemplates.map { ($0.elementId, $0) })
    let existingCPTemplatesById = Dictionary(uniqueKeysWithValues: zip(self.objcTemplates.map { $0.elementId }, self.templates))

    let newTemplates = FCPTabBarTemplate.parseTemplates(newTemplatesData)
    
    /// Keep Flutter CarPlay object if necessary, use new instance.
    self.objcTemplates = newTemplates.map { template in
      if let existing = existingTemplatesById[template.elementId] {
        // For FCPListTemplate, we can merge; for others, use new instance
        if let existingList = existing as? FCPListTemplate, let newList = template as? FCPListTemplate {
          return existingList.merge(with: newList)
        }
        return template
      } else {
        return template // Use new instance
      }
    }

    /// Create new CarPlay template if necessary else keep currents.
    self.templates = newTemplates.map { template in
      if let existing = existingCPTemplatesById[template.elementId] {
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
