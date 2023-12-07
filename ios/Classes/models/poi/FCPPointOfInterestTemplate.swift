//
//  FCPPointOfInterestTemplate.swift
//  flutter_carplay
//
//  Created by Olaf Schneider on 15.02.22.
//

import CarPlay

@available(iOS 14.0, *)
class FCPPointOfInterestTemplate {
    private(set) var _super: CPPointOfInterestTemplate?
    private(set) var elementId: String
    private var title: String
    private var poi: [FCPPointOfInterest]

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        title = obj["title"] as! String
        poi = (obj["poi"] as! [[String: Any]]).map {
            FCPPointOfInterest(obj: $0)
        }
    }

    var get: CPPointOfInterestTemplate {
        var pois: [CPPointOfInterest] = []

        for p in poi {
            pois.append(p.get)
        }

        let pointOfInterestTemplate = CPPointOfInterestTemplate(title: title, pointsOfInterest: pois, selectedIndex: NSNotFound)
        _super = pointOfInterestTemplate
        return pointOfInterestTemplate
    }
}

@available(iOS 14.0, *)
extension FCPPointOfInterestTemplate: FCPRootTemplate {}
