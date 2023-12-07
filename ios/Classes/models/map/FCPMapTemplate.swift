//
//  FCPMapTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import MapKit

@available(iOS 14.0, *)
class FCPMapTemplate: NSObject {
  private(set) var _super: CPMapTemplate?
  private(set) var viewController: UIViewController?
  private(set) var elementId: String
  private var title: String?
  private var mapButtons: [FCPMapButton]
  private var leadingNavigationBarButtons: [FCPBarButton]
  private var trailingNavigationBarButtons: [FCPBarButton]
  private var automaticallyHidesNavigationBar: Bool = false
  private var hidesButtonsWithNavigationBar: Bool = false

  init(obj: [String : Any]) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as? String
	self.mapButtons = (obj["mapButtons"] as! Array<[String : Any]>).map {
            FCPMapButton(obj: $0)
        }
	self.leadingNavigationBarButtons = (obj["leadingNavigationBarButtons"] as! Array<[String : Any]>).map {
            FCPBarButton(obj: $0)
        }
	self.trailingNavigationBarButtons = (obj["trailingNavigationBarButtons"] as! Array<[String : Any]>).map {
				FCPBarButton(obj: $0)
			}
	self.automaticallyHidesNavigationBar = obj["automaticallyHidesNavigationBar"] as! Bool
	self.hidesButtonsWithNavigationBar = obj["hidesButtonsWithNavigationBar"] as! Bool
    self.viewController = FCPMapViewController()
  }

  var get: CPMapTemplate {
    let mapTemplate = CPMapTemplate()

	var mButtons: [CPMapButton] = []
	for button in mapButtons{
		mButtons.append(button.get);
	}

	var lBButtons: [CPBarButton] = []
	for button in leadingNavigationBarButtons{
		lBButtons.append(button.get);
	}

	var tBButtons: [CPBarButton] = []
	for button in trailingNavigationBarButtons{
		tBButtons.append(button.get);
	}

	mapTemplate.mapButtons = mButtons
	mapTemplate.leadingNavigationBarButtons = lBButtons
	mapTemplate.trailingNavigationBarButtons = tBButtons
	mapTemplate.automaticallyHidesNavigationBar = automaticallyHidesNavigationBar
	mapTemplate.hidesButtonsWithNavigationBar = hidesButtonsWithNavigationBar
    mapTemplate.mapDelegate = self.viewController as! CPMapTemplateDelegate

	self._super = mapTemplate
    return mapTemplate
  }
}

@available(iOS 14.0, *)
extension FCPMapTemplate: FCPRootTemplate { }
