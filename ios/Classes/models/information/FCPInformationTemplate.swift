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
      
    private var informationItems: [CPInformationItem]
    private var objcInformationItems: [FCPInformationItem]
    
    private var actions: [CPTextButton]
    private var objcActions: [FCPTextButton]
    
    init(obj: [String : Any]) {
        self.elementId = obj["_elementId"] as! String
        
        self.layout =  obj["layout"] as! String == "twoColumn"
        ? CPInformationTemplateLayout.twoColumn
        : CPInformationTemplateLayout.leading
        
        self.title = obj["title"] as! String
        
        self.objcInformationItems = (obj["informationItems"] as! Array<[String : Any]>).map {
          FCPInformationItem(obj: $0)
        }
        self.informationItems = self.objcInformationItems.map {
          $0.get
        }
        
        self.objcActions = (obj["actions"] as! Array<[String : Any]>).map {
          FCPTextButton(obj: $0)
        }
        self.actions = self.objcActions.map {
          $0.get
        }
    
    }
    
    var get: CPInformationTemplate {
        let informationTemplate = CPInformationTemplate.init(title: self.title,layout:self.layout,items:informationItems,actions:actions);
        return informationTemplate
    }
}
@available(iOS 14.0, *)
extension FCPInformationTemplate: FCPRootTemplate { }
