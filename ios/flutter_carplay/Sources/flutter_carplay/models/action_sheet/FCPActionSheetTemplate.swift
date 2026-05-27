//
//  FCPActionSheetTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 25.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPActionSheetTemplate {
  private(set) var _super: CPActionSheetTemplate?
  private(set) var elementId: String
  private var title: String?
  private var message: String?
  private var tabTitle: String?
  private var systemIcon: String?
  private var showsTabBadge: Bool = false
  private var actions: [CPAlertAction]
  private var objcActions: [FCPAlertAction]

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as? String
    self.message = obj["message"] as? String
    self.tabTitle = obj["tabTitle"] as? String
    self.systemIcon = obj["systemIcon"] as? String
    self.showsTabBadge = obj["showsTabBadge"] as! Bool
    self.objcActions = (obj["actions"] as! [[String: Any]]).map {
      FCPAlertAction(obj: $0, type: FCPAlertActionTypes.ACTION_SHEET)
    }
    self.actions = self.objcActions.map {
      $0.get
    }
  }

  var get: CPActionSheetTemplate {
    let actionSheetTemplate = CPActionSheetTemplate.init(
      title: self.title, message: self.message, actions: self.actions)
    actionSheetTemplate.tabTitle = tabTitle
    actionSheetTemplate.showsTabBadge = showsTabBadge
    if let systemIcon = systemIcon {
      actionSheetTemplate.tabImage = UIImage(systemName: systemIcon)
    }

    actionSheetTemplate.elementId = self.elementId
    self._super = actionSheetTemplate
    return actionSheetTemplate
  }

  public func update(with: FCPActionSheetTemplate) {
  }
}

@available(iOS 14.0, *)
extension FCPActionSheetTemplate: FCPPresentTemplate {}
