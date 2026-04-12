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
  private var tabTitle: String?
  private var systemIcon: String?
  private var showsTabBadge: Bool = false

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as! String
    self.poi = (obj["poi"] as! [[String: Any]]).map {
      FCPPointOfInterest(obj: $0)
    }
    self.tabTitle = obj["tabTitle"] as? String
    self.systemIcon = obj["systemIcon"] as? String
    self.showsTabBadge = obj["showsTabBadge"] as! Bool
  }

  var get: CPTemplate {
    var pois: [CPPointOfInterest] = []

    for p in poi {
      pois.append(p.get)
    }

    let pointOfInterestTemplate = CPPointOfInterestTemplate.init(
      title: self.title, pointsOfInterest: pois, selectedIndex: NSNotFound)
    pointOfInterestTemplate.tabTitle = tabTitle
    pointOfInterestTemplate.showsTabBadge = showsTabBadge
    if let systemIcon = systemIcon {
      pointOfInterestTemplate.tabImage = UIImage(systemName: systemIcon)
    }

    pointOfInterestTemplate.elementId = self.elementId
    self._super = pointOfInterestTemplate
    return pointOfInterestTemplate
  }

  public func update(with: any FCPTemplate) {
    guard let with = with as? FCPPointOfInterestTemplate else {
      return
    }
  }
}

@available(iOS 14.0, *)
extension FCPPointOfInterestTemplate: FCPTemplate {}
