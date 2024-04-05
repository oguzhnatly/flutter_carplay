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

import CarPlay
import heresdk
import UIKit

enum ConstantsEnum {
    static let DEFAULT_MAP_CENTER = GeoCoordinates(latitude: 52.520798, longitude: 13.409408)
    static let DEFAULT_DISTANCE_IN_METERS: Double = 1000 * 2
}

// An app that allows to calculate a route and start navigation, using either platform positioning or
// simulated locations.
class MapController: LongPressDelegate {
    private let viewController: UIViewController
    private let mapView: MapView
    private let routeCalculator: RouteCalculator
    private let navigationHelper: NavigationHelper
    private var mapMarkers = [MapMarker]()
    private var mapPolygons = [MapPolygon]()
    private var mapPolylineList = [MapPolyline]()
    private var startingWaypoint: Waypoint?
    private var destinationWaypoint: Waypoint?
    private var isLongpressDestination = false
    private var messageTextView: UITextView

    /// Initialize the MapController
    /// - Parameters:
    ///   - viewController: ViewController that holds the MapController
    ///   - mapView: MapView that renders the map
    ///   - messageTextView: TextView that displays log messages
    init(viewController: UIViewController, mapView: MapView, messageTextView: UITextView) {
        self.viewController = viewController
        self.mapView = mapView
        self.messageTextView = messageTextView

        let distanceInMeters = MapMeasure(kind: .distance, value: ConstantsEnum.DEFAULT_DISTANCE_IN_METERS)
        mapView.camera.lookAt(point: ConstantsEnum.DEFAULT_MAP_CENTER,
                              zoom: distanceInMeters)

        routeCalculator = RouteCalculator()

        navigationHelper = NavigationHelper(mapView: mapView,
                                            messageTextView: messageTextView)
        navigationHelper.startLocationProvider()

        setLongPressGestureHandler()
        showMessage("Long press to set a destination or use a random one.")
    }

    /// Set destination waypoint for route calculation.
    func setDestinationWaypoint(_ destination: Waypoint) {
        destinationWaypoint = destination
    }

    /// Set the normalized principal point of the VisualNavigator camera.
    func setVisualNavigatorCameraPoint(normalizedPrincipalPoint: heresdk.Anchor2D) {
        navigationHelper.setVisualNavigatorCameraPoint(normalizedPrincipalPoint: normalizedPrincipalPoint)
    }

    /// Calculate a route and start navigation using a location simulator.
    /// Start is map center and destination location is set random within viewport,
    /// unless a destination is set via long press.
    func addRouteSimulatedLocation() {
        calculateRoute(isSimulated: true)
    }

    /// Calculate a route and start navigation using locations from device.
    /// Start is current location and destination is set random within viewport,
    /// unless a destination is set via long press.
    func addRouteDeviceLocation() {
        calculateRoute(isSimulated: false)
    }

    /// Clears the map and resets the route and navigation.
    func clearMapButtonClicked() {
        clearMap()
        isLongpressDestination = false
    }

    /// Enable or disable camera tracking
    func enableCameraTracking() {
        navigationHelper.startCameraTracking()
    }

    /// Enable or disable camera tracking
    func disableCameraTracking() {
        navigationHelper.stopCameraTracking()
    }

    func getIsNavigationInProgress() -> Bool {
        return navigationHelper.getIsNavigationInProgress()
    }

    /// Add a marker on the map.
    /// - Parameters:
    ///   - coordinates: The coordinates of the marker
    ///   - markerImage: The image of the marker
    func addMapMarker(coordinates: GeoCoordinates, markerImage: UIImage, markerSize: CGSize, metadata: heresdk.Metadata?) {
        let marker = mapMarkers.first(where: {
            $0.metadata?.getString(key: "marker") == metadata?.getString(key: "marker")
        })

        if let existingMarker = marker {
            existingMarker.coordinates = coordinates
        } else {
            guard let imageData = markerImage.pngData() else { return }

            let mapImage = MapImage(imageData: imageData,
                                    imageFormat: ImageFormat.png, width: UInt32(markerSize.width), height: UInt32(markerSize.height))
            let mapMarker = MapMarker(at: coordinates,
                                      image: mapImage)
            mapMarker.metadata = metadata
            mapView.mapScene.addMapMarker(mapMarker)
            mapMarkers.append(mapMarker)
        }
    }

    /// Add a polygon on the map.
    /// - Parameters:
    ///   - coordinate: The coordinates of the polygon
    ///   - accuracy: The accuracy of the polygon
    ///   - metadata: The metadata of the polygon
    func addMapPolygon(coordinate: GeoCoordinates, accuracy: Double, metadata: heresdk.Metadata?) {
        let polygon = mapPolygons.first(where: {
            $0.metadata?.getString(key: "polygon") == metadata?.getString(key: "polygon")
        })

        if let existingpolygon = polygon {
            existingpolygon.geometry = GeoPolygon(geoCircle: GeoCircle(center: coordinate, radiusInMeters: accuracy))
        } else {
            let mapPolygon = MapPolygon(geometry: GeoPolygon(geoCircle: GeoCircle(center: coordinate, radiusInMeters: accuracy)), color: UIColor(argb: 0x550B_C7C2))
            mapPolygon.metadata = metadata
            mapView.mapScene.addMapPolygon(mapPolygon)
            mapPolygons.append(mapPolygon)
        }
    }

    /// Calculates a route and start navigation.
    /// - Parameter isSimulated: Whether to use simulated locations.
    private func calculateRoute(isSimulated: Bool) {
        clearMap()

        if !determineRouteWaypoints(isSimulated: isSimulated) {
            return
        }

        // Calculates a car route.
        routeCalculator.calculateRoute(start: startingWaypoint!,
                                       destination: destinationWaypoint!)
        { routingError, routes in
            if let error = routingError {
                self.onNavigationFailed(title: "Error while calculating a route:", message: "\(error)")
                return
            }

            // When routingError is nil, routes is guaranteed to contain at least one route.
            let route = routes!.first
            self.showRouteOnMap(route: route!)
            self.showRouteDetails(route: route!, isSimulated: isSimulated)
        }
    }

    /// Determines the starting and destination waypoints for the route calculation.
    /// - Parameter isSimulated: Whether to use simulated locations.
    /// - Returns: True if waypoints are determined, false if not.
    private func determineRouteWaypoints(isSimulated: Bool) -> Bool {
        // When using real GPS locations, we always start from the current location of user.
        guard let location = navigationHelper.getLastKnownLocation() else {
            onNavigationFailed(title: "Error", message: "No location found.")
            return false
        }
        print("Last known location: \(location.coordinates)")

        startingWaypoint = Waypoint(coordinates: location.coordinates)

        // If a driver is moving, the bearing value can help to improve the route calculation.
        startingWaypoint?.headingInDegrees = location.bearingInDegrees

        mapView.camera.lookAt(point: location.coordinates)

        if isSimulated {
            if destinationWaypoint == nil {
                destinationWaypoint = Waypoint(coordinates: createRandomGeoCoordinatesAroundMapCenter())
            }
        }
        return true
    }

    /// Shows the route details on the screen.
    /// - Parameters:
    ///   - route: The route.
    ///   - isSimulated: Whether to use simulated locations.
    private func showRouteDetails(route: Route, isSimulated: Bool) {
        let estimatedTravelTimeInSeconds = route.duration
        let lengthInMeters = route.lengthInMeters

//        let routeDetails = "Travel Time: " + formatTime(sec: estimatedTravelTimeInSeconds)
//                         + ", Length: " + formatLength(meters: lengthInMeters)

        navigationHelper.startNavigation(route: route, isSimulated: isSimulated)

        // showStartNavigationDialog(title: "Route Details",
//                                  message: routeDetails,
//                                  route: route,
//                                  isSimulated: isSimulated)
    }

    /// Format time in minutes and seconds
    /// - Parameter sec: Time in seconds
    /// - Returns: Time in minutes and seconds
    private func formatTime(sec: Double) -> String {
        let hours: Double = sec / 3600
        let minutes: Double = sec.truncatingRemainder(dividingBy: 3600) / 60

        return "\(Int32(hours)):\(Int32(minutes))"
    }

    /// Format length in kilometers and meters
    /// - Parameter meters: Length in meters
    /// - Returns: Length in kilometers and meters
    private func formatLength(meters: Int32) -> String {
        let kilometers: Int32 = meters / 1000
        let remainingMeters: Int32 = meters % 1000

        return "\(kilometers).\(remainingMeters) km"
    }

    /// Show route on the map
    /// - Parameter route: Route
    private func showRouteOnMap(route: Route) {
        // Show route as polyline.
        let routeGeoPolyline = route.geometry
        let widthInPixels = 20.0
        let polylineColor = UIColor(red: 0, green: 0.56, blue: 0.54, alpha: 0.63)
        do {
            let routeMapPolyline = try MapPolyline(geometry: routeGeoPolyline,
                                                   representation: MapPolyline.SolidRepresentation(
                                                       lineWidth: MapMeasureDependentRenderSize(
                                                           sizeUnit: RenderSize.Unit.pixels,
                                                           size: widthInPixels
                                                       ),
                                                       color: polylineColor,
                                                       capShape: LineCap.round
                                                   ))
            mapView.mapScene.addMapPolyline(routeMapPolyline)
            mapPolylineList.append(routeMapPolyline)
        } catch {
            fatalError("Failed to render MapPolyline. Cause: \(error)")
        }
    }

    /// Clear the map
    func clearMap() {
        clearWaypointMapMarkers()
        clearMapPolygons()
        clearRoute()

        navigationHelper.stopNavigation()
    }

    /// Clear the map markers
    private func clearWaypointMapMarkers() {
        for mapMarker in mapMarkers {
            mapView.mapScene.removeMapMarker(mapMarker)
        }
        mapMarkers.removeAll()
    }

    /// Clear the map polygons
    private func clearMapPolygons() {
        for mapPolygon in mapPolygons {
            mapView.mapScene.removeMapPolygon(mapPolygon)
        }
        mapPolygons.removeAll()
    }

    /// Clear the route
    private func clearRoute() {
        for mapPolyline in mapPolylineList {
            mapView.mapScene.removeMapPolyline(mapPolyline)
        }
        mapPolylineList.removeAll()
    }

    /// Set the long press gesture handler
    private func setLongPressGestureHandler() {
        mapView.gestures.longPressDelegate = self
    }

    /// Conform to LongPressDelegate protocol .
    /// - Parameters:
    ///   - state: The state of the gesture.
    ///   - origin: The point where the gesture began.
    func onLongPress(state: GestureState, origin: Point2D) {
        guard let geoCoordinates = mapView.viewToGeoCoordinates(viewCoordinates: origin) else {
            print("Warning: Long press coordinate is not on map view.")
            return
        }

        if state == GestureState.begin {
            if isLongpressDestination {
                destinationWaypoint = Waypoint(coordinates: geoCoordinates)
                addCircleMapMarker(geoCoordinates: destinationWaypoint!.coordinates, imageName: "green_dot.png")
                showMessage("New long press destination set.")
            } else {
                startingWaypoint = Waypoint(coordinates: geoCoordinates)
                addCircleMapMarker(geoCoordinates: startingWaypoint!.coordinates, imageName: "green_dot.png")
                showMessage("New long press starting point set.")
            }
            isLongpressDestination = !isLongpressDestination
        }
    }

    /// Create a random geo coordinates
    /// - Returns: Random geo coordinates
    private func createRandomGeoCoordinatesAroundMapCenter() -> GeoCoordinates {
        let centerGeoCoordinates = getMapViewCenter()
        let lat = centerGeoCoordinates.latitude
        let lon = centerGeoCoordinates.longitude
        return GeoCoordinates(latitude: getRandom(min: lat - 0.02,
                                                  max: lat + 0.02),
                              longitude: getRandom(min: lon - 0.02,
                                                   max: lon + 0.02))
    }

    /// Get random number
    /// - Parameters:
    ///   - min: Minimum number
    ///   - max: Maximum number
    /// - Returns: Random number
    private func getRandom(min: Double, max: Double) -> Double {
        return Double.random(in: min ... max)
    }

    /// Get the map view center
    /// - Returns: Map view center
    private func getMapViewCenter() -> GeoCoordinates {
        return mapView.camera.state.targetCoordinates
    }

    /// Get the last known location
    /// - Returns: Last known location
    func getLastKnownLocation() -> Location? {
        return navigationHelper.getLastKnownLocation()
    }

    /// Get the marker coordinates
    /// - Parameter markerType: Map Marker type
    /// - Returns: Marker coordinates
    func getMarkerCoordinates(markerType: MapMarkerType) -> GeoCoordinates? {
        let marker = mapMarkers.first(where: {
            $0.metadata?.getString(key: "marker") == markerType.rawValue
        })

        if let existingMarker = marker {
            return existingMarker.coordinates
        }

        return nil
    }

    /// Remove a marker
    /// - Parameter markerType: Map Marker type
    func removeMarker(markerType: MapMarkerType) {
        let marker = mapMarkers.first(where: {
            $0.metadata?.getString(key: "marker") == markerType.rawValue
        })

        if let existingMarker = marker {
            mapView.mapScene.removeMapMarker(existingMarker)
            mapMarkers.removeAll(where: { $0.metadata?.getString(key: "marker") == markerType.rawValue })
        }
    }

    /// Remove a polygon
    /// - Parameter markerType: Map Marker type
    func removePolygon(markerType: MapMarkerType) {
        let polygon = mapPolygons.first(where: {
            $0.metadata?.getString(key: "polygon") == markerType.rawValue
        })

        if let existingPolygon = polygon {
            mapView.mapScene.removeMapPolygon(existingPolygon)
            mapPolygons.removeAll(where: { $0.metadata?.getString(key: "polygon") == markerType.rawValue })
        }
    }

    /// Add a circle map marker
    /// - Parameters:
    ///   - geoCoordinates: Geo coordinates
    ///   - imageName: Image name
    private func addCircleMapMarker(geoCoordinates: GeoCoordinates, imageName: String) {
        guard
            let image = UIImage(named: imageName),
            let imageData = image.pngData()
        else {
            return
        }

        let mapImage = MapImage(pixelData: imageData,
                                imageFormat: ImageFormat.png)
        let mapMarker = MapMarker(at: geoCoordinates,
                                  image: mapImage)
        mapView.mapScene.addMapMarker(mapMarker)
        mapMarkers.append(mapMarker)
    }

    /// Show dialog with navigation options
    /// - Parameters:
    ///   - title: Title of the dialog
    ///   - message: Message of the dialog
    ///   - route: Route to be started
    ///   - isSimulated: Whether to use simulated locations
    private func showStartNavigationDialog(title: String,
                                           message: String,
                                           route: Route,
                                           isSimulated: Bool)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let buttonText = isSimulated ? "Start navigation (simulated)" : "Start navigation (device location)"
        alertController.addAction(UIAlertAction(title: buttonText, style: .default, handler: { _ in
            self.navigationHelper.startNavigation(route: route, isSimulated: isSimulated)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        viewController.present(alertController, animated: true)
    }

    /// Show dialog with title and message
    /// - Parameters:
    ///   - title: Title of the dialog
    ///   - message: Message of the dialog
    private func onNavigationFailed(title: String, message: String) {
        debugPrint("\(title) => \(message)")

        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onNavigationFailedFromCarPlay,
                                         data: [
                                             "message": message,
                                         ])
//        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alertController.addAction(UIAlertAction(title: "OK", style: .default))
//        viewController.present(alertController, animated: true)
    }

    /// A permanent view to show log content.
    /// - Parameter message: Log message to show in the view.
    private func showMessage(_ message: String) {
        messageTextView.text = message
        messageTextView.textColor = .white
        messageTextView.layer.cornerRadius = 8
        messageTextView.isEditable = false
        messageTextView.textAlignment = NSTextAlignment.center
        messageTextView.font = .systemFont(ofSize: 14)
    }
}
