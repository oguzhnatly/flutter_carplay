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

    var markerSize: Double { 30 * mapView.pixelScale }

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

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        let scale = FlutterCarPlaySceneDelegate.carWindow?.screen.scale ?? 1.0
        let topSafeArea = view.safeAreaInsets.top * scale
        let leftSafeArea = view.safeAreaInsets.left * scale
        let rightSafeArea = view.safeAreaInsets.right * scale
        let width = view.bounds.width * scale
        let height = view.bounds.height * scale
        let bannerHeight = bannerView.isHidden ? 0.0 : bannerView.bounds.height

        let cameraPrincipalPoint = Point2D(x: leftSafeArea + (width - leftSafeArea - rightSafeArea) / 2.0, y: topSafeArea + bannerHeight + (height - topSafeArea - bannerHeight) / 2.0)
        mapView.camera.principalPoint = cameraPrincipalPoint

        let anchore2D = Anchor2D(horizontal: cameraPrincipalPoint.x / width, vertical: 0.75)
        mapController?.setVisualNavigatorCameraPoint(normalizedPrincipalPoint: anchore2D)
    }

    // MARK: - configureMapView

    // Completion handler when loading a map scene.
    private func onLoadScene(mapError: MapError?) {
        guard mapError == nil else {
            print("Error: Map scene not loaded, \(String(describing: mapError))")
            return
        }

        if mapController == nil {
            mapController = MapController(viewController: self, mapView: mapView!, messageTextView: UITextView())
        }

        updateMapCoordinatesHandler = { [weak self] mapCoordinates in
            guard let self = self else { return }
            print("mapCoordinates: \(mapCoordinates)")

            if let lastKnownLocation = mapController?.getLastKnownLocation {
                self.renderInitialMarker(coordinates: lastKnownLocation.coordinates, accuracy: lastKnownLocation.horizontalAccuracy)
            } else if let stationCoordinates = mapCoordinates.stationAddressCoordinates {
                self.renderInitialMarker(coordinates: stationCoordinates, accuracy: 0.0)
            }

            if let incidentAddressCoordinates = mapCoordinates.incidentAddressCoordinates {
                self.renderIncidentAddressMarker(coordinates: incidentAddressCoordinates)
            }

            if let destinationAddressCoordinates = mapCoordinates.destinationAddressCoordinates {
                self.renderDestinationAddressMarker(coordinates: destinationAddressCoordinates)
            }
        }

        recenterMapViewHandler = { [weak self] recenterMapPosition in
            guard let self = self else { return }
            print("recenterMapPosition: \(recenterMapPosition)")

//            if state.mapNavigationState.isNavigationInProgress {
//                _enableTracking(true)
//            } else {
            let initialMarkerCoordinates = mapController?.getMarkerCoordinates(metadataKey: "initial_marker")
            let incidentAddressCoordinates = mapController?.getMarkerCoordinates(metadataKey: "incident_address_marker")
            let destinationAddressCoordinates = mapController?.getMarkerCoordinates(metadataKey: "destination_address_marker")

            switch recenterMapPosition {
            case "initialMarker":
                if initialMarkerCoordinates != nil {
//                        flyToCoordinates(initialMarkerCoordinates)
                }

            case "addressMarker":

                if incidentAddressCoordinates != nil, destinationAddressCoordinates != nil {
                    if let geoBox = GeoBox.containing(geoCoordinates: [
                        incidentAddressCoordinates!,
                        destinationAddressCoordinates!,
                    ]) {
                        let scale = FlutterCarPlaySceneDelegate.carWindow?.screen.scale ?? 1.0
                        let topSafeArea = view.safeAreaInsets.top * scale
                        let leftSafeArea = view.safeAreaInsets.left * scale
                        let rightSafeArea = view.safeAreaInsets.right * scale
                        let width = view.bounds.width * scale
                        let height = view.bounds.height * scale
                        let mapRect =
                            Size2D(width: width, height: height)
                        mapView?.camera
                            .lookAtAreaWithGeoOrientationAndViewRectangle(
                                geoBox,
                                GeoOrientationUpdate(0, 0),
                                Rectangle2D(
                                    origin: Point2D(
                                        x: markerSize,
                                        y: markerSize
                                    ),
//                                        *
//                                            _hereMapController!.pixelScale,
                                    size: Size2D(
                                        width: width - markerSize * 2,
                                        height: height - markerSize * 2
                                    )
//                                        *
//                                            _hereMapController!.pixelScale,
                                )
                            )
                    }
                } else if incidentAddressCoordinates != nil {
                    flyToCoordinates(incidentAddressCoordinates)
                }

            case "bothMarkers":

                if initialMarkerCoordinates != nil,
                   incidentAddressCoordinates != nil
                {
                    if let geoBox = GeoBox.containing(geoCoordinates: [
                        initialMarkerCoordinates,
                        incidentAddressCoordinates,
                        if destinationAddressCoordinates != nil {
                            destinationAddressCoordinates
                        },
                    ]) {
                        let scale = FlutterCarPlaySceneDelegate.carWindow?.screen.scale ?? 1.0
                        let topSafeArea = view.safeAreaInsets.top * scale
                        let leftSafeArea = view.safeAreaInsets.left * scale
                        let rightSafeArea = view.safeAreaInsets.right * scale
                        let width = view.bounds.width * scale
                        let height = view.bounds.height * scale
                        let mapRect =
                            Size2D(width: width, height: height)
                        mapView?.camera
                            .lookAtAreaWithGeoOrientationAndViewRectangle(
                                geoBox,
                                GeoOrientationUpdate(0, 0),
                                Rectangle2D(
                                    origin: Point2D(
                                        x: markerSize,
                                        y: markerSize
                                    ),
//                                        *
//                                            _hereMapController!.pixelScale,
                                    size: Size2D(
                                        width: width - markerSize * 2,
                                        height: height - markerSize * 2
                                    )
//                                        *
//                                            _hereMapController!.pixelScale,
                                )
                            )
                    }
                }
            }
        }
    }
//    }
}

// MARK: - Banner & Toast Views

extension FCPMapViewController {
    /// Displays a banner message at the top of the screen
    func showBanner(message: String, color: Int) {
        bannerView.setMessage(message)
        bannerView.setBackgroundColor(color)
        bannerView.isHidden = false
    }

    /// Hides the banner message at the top of the screen.
    func hideBanner() {
        bannerView.isHidden = true
    }

    /// Displays a toast message on the screen for a specified duration.
    func showToast(message: String, duration: TimeInterval = 2.0) {
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
    func showOverlay(primaryTitle: String?, secondaryTitle: String?, subtitle: String?) {
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
        overlayView.isHidden = false
    }

    /// Hides the overlay view on the screen.
    func hideOverlay() {
        overlayView.setPrimaryTitle("00:00:00")
        overlayView.setSecondaryTitle("--")
        overlayView.setSubtitle("--")
        overlayView.isHidden = true
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
        metadata.setString(key: "marker", value: "initial_marker")
        metadata.setString(key: "polygon", value: "initial_marker")

        let image = UIImage().fromFlutterAsset(name: "assets/icons/car_play/position.png")

        mapController?.addMapMarker(coordinates: coordinates, markerImage: image, markerSize: CGSize(width: markerSize, height: markerSize), metadata: metadata)
        mapController?.addMapPolygon(coordinate: coordinates, accuracy: accuracy, metadata: metadata)
    }

    func renderIncidentAddressMarker(coordinates: GeoCoordinates) {
        let metadata = heresdk.Metadata()
        metadata.setString(key: "marker", value: "incident_address_marker")

        let image = UIImage().fromFlutterAsset(name: "assets/icons/car_play/map_marker_big.png")

        let markerSize = 49 * mapView.pixelScale
        mapController?.addMapMarker(coordinates: coordinates, markerImage: image, markerSize: CGSize(width: markerSize, height: markerSize), metadata: metadata)
    }

    /// Adds a destination marker on the map.
    /// - Parameters:
    ///   - coordinates: The coordinates of the marker
    ///   - accuracy: The accuracy of the marker
    func renderDestinationAddressMarker(coordinates: GeoCoordinates) {
        let metadata = heresdk.Metadata()
        metadata.setString(key: "marker", value: "destination_address_marker")

        let image = UIImage().fromFlutterAsset(name: "assets/icons/car_play/map_marker_wp.png")

        let markerSize = 49 * mapView.pixelScale
        mapController?.addMapMarker(coordinates: coordinates, markerImage: image, markerSize: CGSize(width: markerSize, height: markerSize), metadata: metadata)
    }

    func flyToCoordinates(coordinates: GeoCoordinates) {
        let animation = MapCameraAnimationFactory.flyToWithOrientationAndZoom(
            GeoCoordinatesUpdate.fromGeoCoordinates(coordinates),
            GeoOrientationUpdate(0, 0),
            MapMeasure(MapMeasureKind.distance, initDistanceToEarth),
            0.2,
            const Duration(milliseconds: 1000)
        )
        mapView?.camera.startAnimation(animation)
    }

    /// Starts the navigation
    /// - Parameter destination: The destination waypoint
    func startNavigation(trip: CPTrip) {
        let wayPoint = Waypoint(coordinates: GeoCoordinates(latitude: trip.destination.placemark.coordinate.latitude, longitude: trip.destination.placemark.coordinate.longitude))
        mapController?.setDestinationWaypoint(wayPoint)

        mapController?.addRouteSimulatedLocation()
    }

    /// Stops the navigation
    func stopNavigation() {
        mapController?.clearMapButtonClicked()
    }
}
