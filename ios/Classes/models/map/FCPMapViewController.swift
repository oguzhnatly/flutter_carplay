//
// FCPMapViewController.swift
// flutter_carplay
//
// Created by Oğuzhan Atalay on on 19/01/24.
// Copyright © 2024. All rights reserved.
//

import CarPlay
import here_sdk
import heresdk
import MapKit
import UIKit

/// A custom CarPlay map view controller.
class FCPMapViewController: UIViewController, CLLocationManagerDelegate {
    /// The map view associated with the map view controller.
    @IBOutlet var mapView: MapView!

    /// The banner view associated with the map view controller.
    @IBOutlet var bannerView: FCPBannerView! {
        didSet {
            guard let view = bannerView else { return }
            view.isHidden = true
        }
    }

    /// The toast view associated with the map view controller.
    @IBOutlet var toastView: FCPToastView! {
        didSet {
            guard let view = toastView else { return }
            view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            view.layer.cornerRadius = 10
            view.alpha = 0.0
        }
    }

    /// The maximum width of the toast view.
    @IBOutlet var toastViewMaxWidth: NSLayoutConstraint!

    /// The maximum width of the overlay view.
    @IBOutlet var overlayViewMaxWidth: NSLayoutConstraint!

    /// The overlay view associated with the map view controller.
    @IBOutlet var overlayView: FCPOverlayView! {
        didSet {
            guard let view = overlayView else { return }
            view.backgroundColor = .clear
            view.clipsToBounds = true
            view.layer.cornerRadius = 8
            view.isHidden = true
        }
    }

    /// The app associated with the map view controller.
    private var mapController: MapController?

    /// The map marker associated with the map view controller.
    var mapMarker: MapMarker?

    /// The size of the marker pin.
    var markerPinSize: Double { 40 * mapView.pixelScale }

    /// Rectenter map position to adjust the map camera
    var recenterMapPosition: String?

    /// Whether the dashboard scene is active.
    var isDashboardSceneActive: Bool {
        return FlutterCarplayTemplateManager.shared.isDashboardSceneActive
    }

    /// Should show banner
    var shouldShowBanner = false

    /// Should show overlay
    var shouldShowOverlay = false

    /// Map coordinates to render marker on the map
    var mapCoordinates: MapCoordinates?

    /// Overlay view width
    var overlayViewWidth = 0.0

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        // Load the map scene using a map scheme to render the map with.
        mapView.mapScene.loadScene(mapScheme: MapScheme.normalDay, completion: onLoadScene)

        toggleSatelliteViewHandler = { [weak self] showSatelliteView in
            guard let self = self else { return }
            self.mapView.mapScene.loadScene(mapScheme: showSatelliteView ? .satellite : .normalDay, completion: onLoadScene)
        }

        toggleTrafficViewHandler = { [weak self] showTrafficView in
            guard let self = self else { return }

            if showTrafficView {
                self.mapView.mapScene.enableFeatures([
                    MapFeatures.trafficFlow: MapFeatureModes.trafficFlowWithFreeFlow,
                    MapFeatures.trafficIncidents: MapFeatureModes.trafficIncidentsAll,
                ])
            } else {
                self.mapView.mapScene.disableFeatures(
                    [MapFeatures.trafficFlow, MapFeatures.trafficIncidents]
                )
            }
        }
    }

    /// View did appear
    /// - Parameter animated: Animated
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateCameraPrincipalPoint()
    }

    /// View safe area insets
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        if !isDashboardSceneActive {
            updateCameraPrincipalPoint()
        }
    }

    // MARK: - configureMapView

    /// Completion handler when loading a map scene.
    /// - Parameter mapError: Map error
    private func onLoadScene(mapError: MapError?) {
        guard mapError == nil else {
            print("Error: Map scene not loaded, \(String(describing: mapError))")
            return
        }

        if mapController == nil {
            mapController = MapController(viewController: self, mapView: mapView!, messageTextView: UITextView())
        }

        mapView.isMultipleTouchEnabled = true

        // Update the map coordinates
        updateMapCoordinatesHandler = { [weak self] mapCoordinates in
            guard let self = self else { return }
            self.mapCoordinates = mapCoordinates
            if let location = mapController?.lastKnownLocation {
                self.renderInitialMarker(coordinates: location.coordinates, accuracy: location.horizontalAccuracyInMeters ?? 0.0)
            } else if let stationCoordinates = mapCoordinates.stationAddressCoordinates {
                self.renderInitialMarker(coordinates: stationCoordinates, accuracy: 0.0)
            } else {
                mapController?.removeMarker(markerType: .INITIAL)
                mapController?.removePolygon(markerType: .INITIAL)
            }

            if let incidentAddressCoordinates = mapCoordinates.incidentAddressCoordinates {
                self.renderIncidentAddressMarker(coordinates: incidentAddressCoordinates)
            } else {
                mapController?.removeMarker(markerType: .INCIDENT_ADDRESS)
            }

            if let destinationAddressCoordinates = mapCoordinates.destinationAddressCoordinates {
                self.renderDestinationAddressMarker(coordinates: destinationAddressCoordinates)
            } else {
                mapController?.removeMarker(markerType: .DESTINATION_ADDRESS)
            }
        }

        /// Recenter map position
        recenterMapViewHandler = { [weak self] recenterMapPosition in
            guard let self = self else { return }

            self.recenterMapPosition = recenterMapPosition

            if mapController?.navigationHelper.isNavigationInProgress ?? false {
                mapController?.navigationHelper.startCameraTracking()
            } else {
                let initialMarkerCoordinates = mapController?.getMarkerCoordinates(markerType: .INITIAL)
                let incidentAddressCoordinates = mapController?.getMarkerCoordinates(markerType: .INCIDENT_ADDRESS)
                let destinationAddressCoordinates = mapController?.getMarkerCoordinates(markerType: .DESTINATION_ADDRESS)

                switch recenterMapPosition {
                case "initialMarker":
                    if initialMarkerCoordinates != nil {
                        flyToCoordinates(coordinates: initialMarkerCoordinates!)
                    }

                case "addressMarker":

                    if incidentAddressCoordinates != nil, destinationAddressCoordinates != nil {
                        lookAtArea(geoCoordinates: [
                            incidentAddressCoordinates!,
                            destinationAddressCoordinates!,
                        ])

                    } else if incidentAddressCoordinates != nil {
                        flyToCoordinates(coordinates: incidentAddressCoordinates!)
                    }

                case "bothMarkers":

                    if initialMarkerCoordinates != nil,
                       incidentAddressCoordinates != nil
                    {
                        var geoCoordinates = [
                            initialMarkerCoordinates!,
                            incidentAddressCoordinates!,
                        ]
                        if destinationAddressCoordinates != nil {
                            geoCoordinates.append(destinationAddressCoordinates!)
                        }

                        lookAtArea(geoCoordinates: geoCoordinates)
                    }
                default:
                    break
                }
            }
        }
    }

    /// Look at area containing all the markers
    /// - Parameter geoCoordinates: The coordinates of the markers
    func lookAtArea(geoCoordinates: [GeoCoordinates]) {
        if let geoBox = GeoBox.containing(geoCoordinates: geoCoordinates) {
            let scale = FlutterCarplayTemplateManager.shared.carWindow?.screen.scale ?? 1.0
            let topSafeArea = view.safeAreaInsets.top * scale
            let leftSafeArea = view.safeAreaInsets.left * scale
            let rightSafeArea = view.safeAreaInsets.right * scale
            let width = view.frame.width * scale
            let height = view.frame.height * scale
            let bannerHeight = bannerView.isHidden ? 0.0 : bannerView.bounds.height * scale

            let rectangle2D = isDashboardSceneActive ? Rectangle2D(
                origin: Point2D(
                    x: markerPinSize,
                    y: markerPinSize
                ),
                size: Size2D(
                    width: width - markerPinSize * 2,
                    height: height - markerPinSize * 2
                )
            ) : Rectangle2D(
                origin: Point2D(
                    x: leftSafeArea + markerPinSize,
                    y: topSafeArea + bannerHeight + markerPinSize
                ),
                size: Size2D(
                    width: width - leftSafeArea - rightSafeArea - markerPinSize * 2,
                    height: height - topSafeArea - bannerHeight - markerPinSize * 2
                )
            )

            mapView?.camera.lookAt(area: geoBox, orientation: GeoOrientationUpdate(bearing: 0, tilt: 0), viewRectangle: rectangle2D)
        }
    }

    /// Update the camera principal point
    fileprivate func updateCameraPrincipalPoint() {
        let scale = FlutterCarplayTemplateManager.shared.carWindow?.screen.scale ?? 1.0
        let topSafeArea = view.safeAreaInsets.top * scale
        let leftSafeArea = view.safeAreaInsets.left * scale
        let rightSafeArea = view.safeAreaInsets.right * scale
        let width = view.frame.width * scale
        let height = view.frame.height * scale

        if isDashboardSceneActive {
            let cameraPrincipalPoint = Point2D(x: width / 2.0, y: height / 2.0)
            mapView.camera.principalPoint = cameraPrincipalPoint

            let anchor2D = Anchor2D(horizontal: 0.5, vertical: 0.75)
            mapController?.navigationHelper.setVisualNavigatorCameraPoint(normalizedPrincipalPoint: anchor2D)

        } else {
            let bannerHeight = bannerView.isHidden ? 0.0 : bannerView.bounds.height * scale
            let overlayViewWidth = overlayView.isHidden ? 0.0 : overlayView.bounds.width * scale + 16.0

            let cameraPrincipalPoint = Point2D(x: leftSafeArea + overlayViewWidth + (width - leftSafeArea - rightSafeArea - overlayViewWidth) / 2.0, y: topSafeArea + bannerHeight + (height - topSafeArea - bannerHeight) / 2.0)
            mapView.camera.principalPoint = cameraPrincipalPoint

            let anchor2D = Anchor2D(horizontal: cameraPrincipalPoint.x / width, vertical: 0.75)
            mapController?.navigationHelper.setVisualNavigatorCameraPoint(normalizedPrincipalPoint: anchor2D)
        }

        if let recenterPosition = recenterMapPosition {
            recenterMapViewHandler?(recenterPosition)
        }
    }
}

// MARK: - Banner & Toast Views

extension FCPMapViewController {
    /// Displays a banner message at the top of the screen
    /// - Parameters:
    ///   - message: The message to display
    ///   - color: The color of the banner
    func showBanner(message: String, color: Int) {
        shouldShowBanner = true
        bannerView.setMessage(message)
        bannerView.setBackgroundColor(color)
        bannerView.isHidden = isDashboardSceneActive

        if !isDashboardSceneActive {
            updateCameraPrincipalPoint()
        }
    }

    /// Hides the banner message at the top of the screen.
    func hideBanner() {
        bannerView.isHidden = true
        shouldShowBanner = false
    }

    /// Displays a toast message on the screen for a specified duration.
    /// - Parameters:
    ///   - message: The message to display
    ///   - duration: The duration of the toast
    func showToast(message: String, duration: TimeInterval = 2.0) {
        guard !isDashboardSceneActive else { return }

        // Cancel any previous toast
        NSObject.cancelPreviousPerformRequests(withTarget: self)

        toastViewMaxWidth.constant = view.bounds.size.width * 0.65

        // Set the message and show the toast
        toastView.setMessage(message)

        // Fade in the toast
        toastView.alpha = 1.0

        // Dismiss the toast after the specified duration
        perform(#selector(dismissToast), with: nil, afterDelay: duration)
    }

    /// Hides the toast message on the screen.
    @objc private func dismissToast() {
        UIView.animate(withDuration: 0.3) {
            self.toastView.alpha = 0.0
        }
    }

    /// Displays an overlay view on the screen.
    /// - Parameters:
    ///   - primaryTitle: The primary title of the overlay view
    ///   - secondaryTitle: The secondary title of the overlay view
    ///   - subtitle: The subtitle of the overlay view
    func showOverlay(primaryTitle: String?, secondaryTitle: String?, subtitle: String?) {
        shouldShowOverlay = true
        overlayViewMaxWidth.constant = view.bounds.size.width * 0.65

        if let primaryTitle = primaryTitle {
            overlayView.setPrimaryTitle(primaryTitle)
        }
        if let secondaryTitle = secondaryTitle {
            overlayView.setSecondaryTitle(secondaryTitle)
        }
        if let subtitle = subtitle {
            overlayView.setSubtitle(subtitle)
        }
        overlayView.isHidden = isDashboardSceneActive

        if !isDashboardSceneActive, overlayViewWidth != overlayView.bounds.width {
            overlayViewWidth = overlayView.bounds.width
            updateCameraPrincipalPoint()
        }
    }

    /// Hides the overlay view on the screen.
    func hideOverlay() {
        overlayView.setPrimaryTitle("00:00:00")
        overlayView.setSecondaryTitle("--")
        overlayView.setSubtitle("--")
        overlayView.isHidden = true
        overlayViewWidth = 0.0
        shouldShowOverlay = false
    }

    /// Dashboard scene is active
    func dashboardSceneDidBecomeActive() {
        bannerView.isHidden = true
        overlayView.isHidden = true
    }

    /// CarPlay scene is active
    func carplaySceneDidBecomeActive() {
        bannerView.isHidden = !shouldShowBanner
        overlayView.isHidden = !shouldShowOverlay
    }
}

// MARK: - Map Helper functions

extension FCPMapViewController {
    /// Adds a initial marker on the map.
    /// - Parameters:
    ///   - coordinates: The coordinates of the marker
    ///   - accuracy: The accuracy of the marker
    func renderInitialMarker(coordinates: GeoCoordinates, accuracy: Double) {
        let metadata = heresdk.Metadata()
        metadata.setString(key: "marker", value: MapMarkerType.INITIAL.rawValue)
        metadata.setString(key: "polygon", value: MapMarkerType.INITIAL.rawValue)

        let image = UIImage().fromFlutterAsset(name: "assets/icons/carplay/position.png")
        let markerSize = 30 * mapView.pixelScale

        mapController?.addMapMarker(coordinates: coordinates, markerImage: image, markerSize: CGSize(width: markerSize, height: markerSize), metadata: metadata)
        mapController?.addMapPolygon(coordinate: coordinates, accuracy: accuracy, metadata: metadata)
    }

    /// Adds an incident marker on the map.
    /// - Parameter coordinates: The coordinates of the marker
    func renderIncidentAddressMarker(coordinates: GeoCoordinates) {
        let metadata = heresdk.Metadata()
        metadata.setString(key: "marker", value: MapMarkerType.INCIDENT_ADDRESS.rawValue)

        let image = UIImage().fromFlutterAsset(name: "assets/icons/carplay/map_marker_big.png")

        mapController?.addMapMarker(coordinates: coordinates, markerImage: image, markerSize: CGSize(width: markerPinSize, height: markerPinSize), metadata: metadata)
    }

    /// Adds a destination marker on the map.
    /// - Parameters:
    ///   - coordinates: The coordinates of the marker
    ///   - accuracy: The accuracy of the marker
    func renderDestinationAddressMarker(coordinates: GeoCoordinates) {
        let metadata = heresdk.Metadata()
        metadata.setString(key: "marker", value: MapMarkerType.DESTINATION_ADDRESS.rawValue)

        let image = UIImage().fromFlutterAsset(name: "assets/icons/carplay/map_marker_wp.png")

        mapController?.addMapMarker(coordinates: coordinates, markerImage: image, markerSize: CGSize(width: markerPinSize, height: markerPinSize), metadata: metadata)
    }

    /// Fly to coordinates with animation on the map.
    /// - Parameters:
    ///   - coordinates: The coordinates of the marker
    ///   - bowFactor: The bow factor of the animation
    ///   - duration: The duration of the animation
    func flyToCoordinates(coordinates: GeoCoordinates, bowFactor: Double = 0.2, duration: TimeInterval = TimeInterval(1)) {
        print("principlePoint at fly to: \(mapView.camera.principalPoint)")

        let animation = MapCameraAnimationFactory.flyTo(target: GeoCoordinatesUpdate(coordinates), orientation: GeoOrientationUpdate(bearing: 0.0, tilt: 0.0), zoom: MapMeasure(kind: .distance, value: ConstantsEnum.DEFAULT_DISTANCE_IN_METERS), bowFactor: bowFactor, duration: duration)

        mapView.camera.startAnimation(animation)
    }

    /// Starts the navigation
    /// - Parameter destination: The destination waypoint
    func startNavigation(trip: CPTrip) {
        let wayPoint = Waypoint(coordinates: GeoCoordinates(latitude: trip.destination.placemark.coordinate.latitude, longitude: trip.destination.placemark.coordinate.longitude))
        mapController?.setDestinationWaypoint(wayPoint)

        mapController?.addRouteDeviceLocation()
    }

    /// Stops the navigation
    func stopNavigation() {
        mapController?.clearMapButtonClicked()
        if let mapCoordinates = mapCoordinates {
            updateMapCoordinatesHandler?(mapCoordinates)
        }
    }

    /// Pans the camera in the specified direction
    /// - Parameter direction: The direction to pan
    func panInDirection(_ direction: CPMapTemplate.PanDirection) {
        MemoryLogger.shared.appendEvent("Panning to \(direction).")

        var offset = mapView.camera.principalPoint
        switch direction {
        case .down:
            offset.y += mapView.bounds.size.height / 2.0
        case .up:
            offset.y -= mapView.bounds.size.height / 2.0
        case .left:
            offset.x -= mapView.bounds.size.width / 2.0
        case .right:
            offset.x += mapView.bounds.size.width / 2.0
        default:
            break
        }

        // Update the Map camera position
        if let coordinates = mapView.viewToGeoCoordinates(viewCoordinates: offset) {
            flyToCoordinates(coordinates: coordinates, bowFactor: 0.0, duration: TimeInterval(0.5))
        }
    }
}
