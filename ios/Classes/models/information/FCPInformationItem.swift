//
//  FCPInformationItem.swift
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

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        title = obj["title"] as? String
        detail = obj["detail"] as? String
    }

    var get: CPInformationItem {
        let informationItem = CPInformationItem(title: title, detail: detail)
        _super = informationItem
        return informationItem
    }
}
