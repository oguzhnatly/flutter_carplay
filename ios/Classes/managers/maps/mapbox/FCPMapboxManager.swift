//
//  FCPMapboxManager.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/12/2021.
//

//import CarPlay
//import MapboxNavigation
//import MapboxCoreNavigation
//import MapboxDirections
//
//let CarPlayWaypointKey: String = "MBCarPlayWaypoint"
//
//@available(iOS 14.0, *)
//class FCPMapboxManager: NSObject, CarPlayManagerDelegate {
//  func carPlayManager(_ carPlayManager: CarPlayManager,
//                      navigationServiceFor routeResponse: RouteResponse,
//                      routeIndex: Int,
//                      routeOptions: RouteOptions,
//                      desiredSimulationMode: SimulationMode) -> NavigationService? {
//    if let navigationViewController = currentUIWindow!.rootViewController?.presentedViewController as? NavigationViewController,
//      let navigationService = navigationViewController.navigationService {
//      return navigationService
//    }
//
//    return MapboxNavigationService(routeResponse: routeResponse, routeIndex: routeIndex, routeOptions: routeOptions, simulating: desiredSimulationMode)
//  }
//
//  func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) {
//    carPlayManager.carPlayNavigationViewController?.compassView.isHidden = false
//    carPlayManager.carPlayNavigationViewController?.routeLineTracksTraversal = true
//  }
//
//  func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
//    print("[FCPMapbox] CarPlay Manager did end navigation.")
//  }
//
//  func carPlayManager(_ carPlayManager: CarPlayManager, shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool {
//    return true
//  }
//
//  func carPlayManager(_ carPlayManager: CarPlayManager,
//                      leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
//                      in carPlayTemplate: CPTemplate,
//                      for activity: CarPlayActivity) -> [CPBarButton]? {
////    guard let interfaceController = FCPManagers.Mapbox.interfaceController else {
////      return nil
////    }
//
////    switch activity {
////    case .browsing:
////
////    default:
////
////    }
//    return nil
//  }
//
//  func carPlayManager(_ carPlayManager: CarPlayManager,
//                      didFailToFetchRouteBetween waypoints: [Waypoint]?,
//                      options: RouteOptions,
//                      error: DirectionsError) -> CPNavigationAlert? {
//    let title = NSLocalizedString("CARPLAY_OK", bundle: .main, value: "OK", comment: "CPAlertTemplate OK button title")
//
//    let action = CPAlertAction(title: title, style: .default, handler: { _ in })
//
//    let alert = CPNavigationAlert(titleVariants: [error.localizedDescription], subtitleVariants: [error.failureReason ?? ""], image: nil, primaryAction: action, secondaryAction: nil, duration: 5.0)
//
//    return alert
//  }
//
//  func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in carPlayTemplate: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
//    switch activity {
//    case .previewing:
//      let disableSimulateText = NSLocalizedString("CARPLAY_DISABLE_SIMULATION",
//                                                  bundle: .main,
//                                                  value: "Disable Simulation",
//                                                  comment: "CPBarButton title, which allows to disable location simulation")
//
//      let enableSimulateText = NSLocalizedString("CARPLAY_ENABLE_SIMULATION",
//                                                 bundle: .main,
//                                                 value: "Enable Simulation",
//                                                 comment: "CPBarButton title, which allows to enable location simulation")
//
//      let simulationButton = CPBarButton(title: carPlayManager.simulatesLocations ? disableSimulateText : enableSimulateText, handler: { barButton in
//          carPlayManager.simulatesLocations = !carPlayManager.simulatesLocations
//          barButton.title = carPlayManager.simulatesLocations ? disableSimulateText : enableSimulateText
//      })
//      return [simulationButton]
//    case .browsing:
//      let favoriteTemplateButton = CPBarButton(image: UIImage(named: "carplay_star", in: nil, compatibleWith: traitCollection)!, handler: { button in
//          let listTemplate = self.favoritesListTemplate()
//          listTemplate.delegate = self
//          carPlayManager.interfaceController?.pushTemplate(listTemplate, animated: true)
//      })
//      return [favoriteTemplateButton]
//    default:
//      return nil
//    }
//  }
//
//  func carPlayManager(_ carPlayManager: CarPlayManager,
//                      mapButtonsCompatibleWith traitCollection: UITraitCollection,
//                      in carPlayTemplate: CPTemplate,
//                      for activity: CarPlayActivity) -> [CPMapButton]? {
//    switch activity {
//    case .browsing:
//      guard let carPlayMapViewController = carPlayManager.carPlayMapViewController,
//        let mapTemplate = carPlayTemplate as? CPMapTemplate else {
//        return nil
//      }
//
//      var mapButtons = [
//        carPlayMapViewController.recenterButton,
//        carPlayMapViewController.zoomInButton,
//        carPlayMapViewController.zoomOutButton
//    ]
//
//      mapButtons.insert(carPlayMapViewController.panningInterfaceDisplayButton(for: mapTemplate), at: 1)
//      return mapButtons
//    case .previewing, .navigating, .panningInBrowsingMode:
//      return nil
//    }
//  }
//
//  func favoritesListTemplate() -> CPListTemplate {
//    let mapboxSFItem = CPListItem(text: FavoritesList.POI.mapboxSF.rawValue,
//                                  detailText: FavoritesList.POI.mapboxSF.subTitle)
//    mapboxSFItem.userInfo = [
//      CarPlayWaypointKey: Waypoint(location: FavoritesList.POI.mapboxSF.location)
//    ]
//
//    let timesSquareItem = CPListItem(text: FavoritesList.POI.timesSquare.rawValue,
//                                     detailText: FavoritesList.POI.timesSquare.subTitle)
//    timesSquareItem.userInfo = [
//      CarPlayWaypointKey: Waypoint(location: FavoritesList.POI.timesSquare.location)
//    ]
//
//    let listSection = CPListSection(items: [mapboxSFItem, timesSquareItem])
//
//    let title = NSLocalizedString("CARPLAY_FAVORITES_LIST", bundle: .main, value: "Favorites List", comment: "CPListTemplate title, which shows list of favorite destinations")
//
//    return CPListTemplate(title: title, sections: [listSection])
//  }
//}
//
//@available(iOS 12.0, *)
//extension FCPMapboxManager: CPListTemplateDelegate {
//    func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem, completionHandler: @escaping () -> Void) {
//      if let userInfo = item.userInfo as? [String: Any],
//        let waypoint = userInfo[CarPlayWaypointKey] as? Waypoint {
////        carPlayManager.previewRoutes(to: waypoint, completionHandler: completionHandler)
//        return
//      }
//
//      completionHandler()
//    }
//}
