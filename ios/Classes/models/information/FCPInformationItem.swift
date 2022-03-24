//
//  FCPPointOfInterestTemplate.swift
//  flutter_carplay
//
//  Created by Olaf Schneider on 17.02.22.
//

import CarPlay

@available(iOS 14.0, *)
class FCPInformationItem {
    private(set) var _super: CPInformationItem?
    private(set) var elementId: String
    private var title: String?
    private var detail: String?
    

    
    init(obj: [String : Any]) {
        self.elementId = obj["_elementId"] as! String
        self.title = obj["title"] as? String
        self.detail = obj["detail"] as? String
    }
    
    var get: CPInformationItem {
        let informationItem = CPInformationItem.init(title: self.title, detail: self.detail)
        self._super = informationItem
        return informationItem
    }
}

