//
//  FCPGridTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPGridTemplate {
  private(set) var _super: CPGridTemplate?
  private(set) var elementId: String
  private var title: String
  private var tabTitle: String?
  private var systemIcon: String?
  private var showsTabBadge: Bool = false
  private var buttons: [CPGridButton]
  private var objcButtons: [FCPGridButton]

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as! String
    self.tabTitle = obj["tabTitle"] as? String
    self.systemIcon = obj["systemIcon"] as? String
    self.showsTabBadge = obj["showsTabBadge"] as! Bool
    self.objcButtons = (obj["buttons"] as! [[String: Any]]).map {
      FCPGridButton(obj: $0)
    }
    self.buttons = self.objcButtons.map {
      $0.get
    }
  }

  var get: CPTemplate {
    let gridTemplate = CPGridTemplate.init(title: self.title, gridButtons: self.buttons)
    gridTemplate.elementId = self.elementId
    gridTemplate.tabTitle = tabTitle
    gridTemplate.showsTabBadge = showsTabBadge
    if let systemIcon = systemIcon {
      resolveTabIcon(systemIcon) { gridTemplate.tabImage = $0 }
    }

    self._super = gridTemplate
    return gridTemplate
  }

  /// The mutable wrappers backing this template's grid buttons.
  ///
  /// Each element's `_super` is the very `CPGridButton` instance handed to
  /// `CPGridTemplate`, which is what allows a single button to be updated in
  /// place by `elementId`.
  public func getFCPGridButtons() -> [FCPGridButton] {
    return objcButtons
  }

  public func update(with: any FCPTemplate) {
    guard let with = with as? FCPGridTemplate else {
      return
    }
  }
}

@available(iOS 14.0, *)
extension FCPGridTemplate: FCPTemplate {}
