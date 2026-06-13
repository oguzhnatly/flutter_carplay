//
//  FCPPointOfInterestTemplate.swift
//  flutter_carplay
//
//  Created by Olaf Schneider on 15.02.22.
//

import CarPlay

@available(iOS 14.0, *)
class FCPInformationTemplate {
  private(set) var _super: CPInformationTemplate?
  private(set) var elementId: String
  private var title: String
  private var layout: CPInformationTemplateLayout
  private var tabTitle: String?
  private var systemIcon: String?
  private var showsTabBadge: Bool = false
  private var informationItems: [CPInformationItem]
  private var objcInformationItems: [FCPInformationItem]

  private var actions: [CPTextButton]
  private var objcActions: [FCPTextButton]

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String

    self.layout =
      obj["layout"] as! String == "twoColumn"
      ? CPInformationTemplateLayout.twoColumn
      : CPInformationTemplateLayout.leading
    self.title = obj["title"] as! String
    self.tabTitle = obj["tabTitle"] as? String
    self.systemIcon = obj["systemIcon"] as? String
    self.showsTabBadge = obj["showsTabBadge"] as! Bool
    self.objcInformationItems = (obj["informationItems"] as! [[String: Any]]).map {
      FCPInformationItem(obj: $0)
    }
    self.informationItems = self.objcInformationItems.map {
      $0.get
    }
    self.objcActions = (obj["actions"] as! [[String: Any]]).map {
      FCPTextButton(obj: $0)
    }
    self.actions = self.objcActions.map {
      $0.get
    }
  }

  var get: CPTemplate {
    let informationTemplate = CPInformationTemplate.init(
      title: self.title, layout: self.layout, items: informationItems, actions: actions)
    informationTemplate.tabTitle = tabTitle
    informationTemplate.showsTabBadge = showsTabBadge
    if let systemIcon = systemIcon {
      informationTemplate.tabImage = UIImage(systemName: systemIcon)
    }
    informationTemplate.elementId = self.elementId
    self._super = informationTemplate
    return informationTemplate
  }

  public func update(with: any FCPTemplate) {
    guard let with = with as? FCPInformationTemplate else {
      return
    }
  }

  public func updateInformationItems(items: [FCPInformationItem]) {
    self.objcInformationItems = items
    self.informationItems = items.map { $0.get }
    _super?.items = self.informationItems
  }

  public func updateActions(actions: [FCPTextButton]) {
    self.objcActions = actions
    self.actions = actions.map { $0.get }
    _super?.actions = self.actions
  }
}
@available(iOS 14.0, *)
extension FCPInformationTemplate: FCPTemplate {}
