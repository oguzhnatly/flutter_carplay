//
//  FCPListSection.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPListSection {
    private(set) var _super: CPListSection?
    private(set) var elementId: String
    private var header: String?
    private var items: [CPListTemplateItem]
    private var objcItems: [FCPListItem]

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        header = obj["header"] as? String
        objcItems = (obj["items"] as! [[String: Any]]).map {
            FCPListItem(obj: $0)
        }
        items = objcItems.map {
            $0.get
        }
    }

    var get: CPListSection {
        let listSection = CPListSection(items: items, header: header, sectionIndexTitle: header)
        _super = listSection
        return listSection
    }

    public func getItems() -> [FCPListItem] {
        return objcItems
    }
}
