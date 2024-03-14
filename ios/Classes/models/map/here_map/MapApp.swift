/*
 * Copyright (C) 2019-2024 HERE Europe B.V.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 * License-Filename: LICENSE
 */

import heresdk
import UIKit
import CarPlay

enum ConstantsEnum {
    static let DEFAULT_MAP_CENTER = GeoCoordinates(latitude: 52.520798, longitude: 13.409408)
    static let DEFAULT_DISTANCE_IN_METERS: Double = 1000 * 2
}

// An app that allows to calculate a route and start navigation, using either platform positioning or
// simulated locations.
var navSession: CPNavigationSession?

class MapApp: LongPressDelegate {

    private let viewController: UIViewController
    private let mapView: MapView
    private let routeCalculator: RouteCalculator
    private let navigationExample: NavigationExample
    private var mapMarkers = [MapMarker]()
    private var mapPolylineList = [MapPolyline]()
    private var startingWaypoint: Waypoint?
    private var destinationWaypoint: Waypoint?
    private var isLongpressDestination = false
    private var messageTextView: UITextView

    init(viewController: UIViewController, mapView: MapView, messageTextView: UITextView) {
        self.viewController = viewController
        self.mapView = mapView
        self.messageTextView = messageTextView

        let distanceInMeters = MapMeasure(kind: .distance, value: ConstantsEnum.DEFAULT_DISTANCE_IN_METERS)
        mapView.camera.lookAt(point: ConstantsEnum.DEFAULT_MAP_CENTER,
                              zoom: distanceInMeters)

        routeCalculator = RouteCalculator()

        navigationExample = NavigationExample(mapView: mapView,
                                              messageTextView: messageTextView)
        navigationExample.startLocationProvider()

        setLongPressGestureHandler()
        showMessage("Long press to set a destination or use a random one.")
    }

    // Calculate a route and start navigation using a location simulator.
    // Start is map center and destination location is set random within viewport,
    // unless a destination is set via long press.
    func addRouteSimulatedLocationButtonClicked() {
        calculateRoute(isSimulated: true)
    }

    // Calculate a route and start navigation using locations from device.
    // Start is current location and destination is set random within viewport,
    // unless a destination is set via long press.
    func addRouteDeviceLocationButtonClicked() {
        calculateRoute(isSimulated: false)
    }

    func clearMapButtonClicked() {
        clearMap()
        isLongpressDestination = false
    }

    func enableCameraTracking() {
        navigationExample.startCameraTracking()
    }

    func disableCameraTracking() {
        navigationExample.stopCameraTracking()
    }

    private func calculateRoute(isSimulated: Bool) {
        clearMap()

        if !determineRouteWaypoints(isSimulated: isSimulated) {
            return
        }

        // Calculates a car route.
        routeCalculator.calculateRoute(start: startingWaypoint!,
                                       destination: destinationWaypoint!) { (routingError, routes) in
           if let error = routingError {
               self.showDialog(title: "Error while calculating a route:", message: "\(error)")
               return
           }

           // When routingError is nil, routes is guaranteed to contain at least one route.
           let route = routes!.first
           self.showRouteOnMap(route: route!)
           self.showRouteDetails(route: route!, isSimulated: isSimulated)
       }
    }

    private func determineRouteWaypoints(isSimulated: Bool) -> Bool {
        // When using real GPS locations, we always start from the current location of user.
        if !isSimulated {
            guard let location = navigationExample.getLastKnownLocation() else {
                showDialog(title: "Error", message: "No location found.")
                return false
            }

            startingWaypoint = Waypoint(coordinates: location.coordinates)

            // If a driver is moving, the bearing value can help to improve the route calculation.
            startingWaypoint?.headingInDegrees = location.bearingInDegrees

            mapView.camera.lookAt(point: location.coordinates)
        }

        if (startingWaypoint == nil) {
            startingWaypoint = Waypoint(coordinates: createRandomGeoCoordinatesAroundMapCenter())
        }

        if (destinationWaypoint == nil) {
            destinationWaypoint = Waypoint(coordinates: createRandomGeoCoordinatesAroundMapCenter())
        }

        return true
    }

    private func showRouteDetails(route: Route, isSimulated: Bool) {
        let estimatedTravelTimeInSeconds = route.duration
        let lengthInMeters = route.lengthInMeters

        let routeDetails = "Travel Time: " + formatTime(sec: estimatedTravelTimeInSeconds)
                         + ", Length: " + formatLength(meters: lengthInMeters)

        self.navigationExample.startNavigation(route: route, isSimulated: isSimulated)

        //showStartNavigationDialog(title: "Route Details",
//                                  message: routeDetails,
//                                  route: route,
//                                  isSimulated: isSimulated)
    }

    private func formatTime(sec: Double) -> String {
        let hours: Double = sec / 3600
        let minutes: Double = sec.truncatingRemainder(dividingBy: 3600) / 60

        return "\(Int32(hours)):\(Int32(minutes))"
    }

    private func formatLength(meters: Int32) -> String {
        let kilometers: Int32 = meters / 1000
        let remainingMeters: Int32 = meters % 1000

        return "\(kilometers).\(remainingMeters) km"
    }

    private func showRouteOnMap(route: Route) {
        // Show route as polyline.
        let routeGeoPolyline = route.geometry
        let widthInPixels = 20.0
        let polylineColor = UIColor(red: 0, green: 0.56, blue: 0.54, alpha: 0.63)
        do {
            let routeMapPolyline =  try MapPolyline(geometry: routeGeoPolyline,
                                                    representation: MapPolyline.SolidRepresentation(
                                                        lineWidth: MapMeasureDependentRenderSize(
                                                            sizeUnit: RenderSize.Unit.pixels,
                                                            size: widthInPixels),
                                                        color: polylineColor,
                                                        capShape: LineCap.round))
            mapView.mapScene.addMapPolyline(routeMapPolyline)
            mapPolylineList.append(routeMapPolyline)
        } catch let error {
            fatalError("Failed to render MapPolyline. Cause: \(error)")
        }
    }

    func clearMap() {
        clearWaypointMapMarker()
        clearRoute()

        navigationExample.stopNavigation()
    }

    private func clearWaypointMapMarker() {
        for mapMarker in mapMarkers {
            mapView.mapScene.removeMapMarker(mapMarker)
        }
        mapMarkers.removeAll()
    }

    private func clearRoute() {
        for mapPolyline in mapPolylineList {
            mapView.mapScene.removeMapPolyline(mapPolyline)
        }
        mapPolylineList.removeAll()
    }

    private func setLongPressGestureHandler() {
        mapView.gestures.longPressDelegate = self
    }

    // Conform to LongPressDelegate protocol.
    func onLongPress(state: GestureState, origin: Point2D) {
        guard let geoCoordinates = mapView.viewToGeoCoordinates(viewCoordinates: origin) else {
            print("Warning: Long press coordinate is not on map view.")
            return
        }

        if state == GestureState.begin {
            if (isLongpressDestination) {
                destinationWaypoint = Waypoint(coordinates: geoCoordinates);
                addCircleMapMarker(geoCoordinates: destinationWaypoint!.coordinates, imageName: "green_dot.png")
                showMessage("New long press destination set.")
            } else {
                startingWaypoint = Waypoint(coordinates: geoCoordinates)
                addCircleMapMarker(geoCoordinates: startingWaypoint!.coordinates, imageName: "green_dot.png")
                showMessage("New long press starting point set.")
            }
            isLongpressDestination = !isLongpressDestination;
        }
    }

    private func createRandomGeoCoordinatesAroundMapCenter() -> GeoCoordinates {
        let centerGeoCoordinates = getMapViewCenter()
        let lat = centerGeoCoordinates.latitude
        let lon = centerGeoCoordinates.longitude
        return GeoCoordinates(latitude: getRandom(min: lat - 0.02,
                                                  max: lat + 0.02),
                              longitude: getRandom(min: lon - 0.02,
                                                   max: lon + 0.02))
    }

    private func getRandom(min: Double, max: Double) -> Double {
        return Double.random(in: min ... max)
    }

    private func getMapViewCenter() -> GeoCoordinates {
        return mapView.camera.state.targetCoordinates
    }

    private func addCircleMapMarker(geoCoordinates: GeoCoordinates, imageName: String) {
        guard
            let image = UIImage(named: imageName),
            let imageData = image.pngData() else {
                return
        }

        let mapImage = MapImage(pixelData: imageData,
                                imageFormat: ImageFormat.png)
        let mapMarker = MapMarker(at: geoCoordinates,
                                  image: mapImage)
        mapView.mapScene.addMapMarker(mapMarker)
        mapMarkers.append(mapMarker)
    }

    private func showStartNavigationDialog(title: String,
                                           message: String,
                                           route: Route,
                                           isSimulated: Bool) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let buttonText = isSimulated ? "Start navigation (simulated)" : "Start navigation (device location)"
        alertController.addAction(UIAlertAction(title: buttonText, style: .default, handler: { (alertAction) -> Void in
            self.navigationExample.startNavigation(route: route, isSimulated: isSimulated)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        viewController.present(alertController, animated: true)
    }

    private func showDialog(title: String, message: String) {
        debugPrint("\(title) => \(message)");
//        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alertController.addAction(UIAlertAction(title: "OK", style: .default))
//        viewController.present(alertController, animated: true)
    }

    // A permanent view to show log content.
    private func showMessage(_ message: String) {
        messageTextView.text = message
        messageTextView.textColor = .white
        messageTextView.layer.cornerRadius = 8
        messageTextView.isEditable = false
        messageTextView.textAlignment = NSTextAlignment.center
        messageTextView.font = .systemFont(ofSize: 14)
    }
}
