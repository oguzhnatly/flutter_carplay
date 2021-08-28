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
  private var actions: [CPAlertAction]
  private var objcActions: [FCPAlertAction]
  
  init(obj: [String : Any]) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as? String
    self.message = obj["message"] as? String
    self.objcActions = (obj["actions"] as! Array<[String : Any]>).map {
      FCPAlertAction(obj: $0, type: FCPAlertActionTypes.ACTION_SHEET)
    }
    self.actions = self.objcActions.map {
      $0.get
    }
  }
  
  var get: CPActionSheetTemplate {
    let actionSheetTemplate = CPActionSheetTemplate.init(title: self.title, message: self.message, actions: self.actions)
    self._super = actionSheetTemplate
    return actionSheetTemplate
  }
}

@available(iOS 14.0, *)
extension FCPActionSheetTemplate: FCPPresentTemplate { }
