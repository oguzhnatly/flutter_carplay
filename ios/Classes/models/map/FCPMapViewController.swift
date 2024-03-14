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
    private var mapApp: MapApp!

    /// Create a CLLocationManager and assign a delegate
    let locationManager = CLLocationManager()

    /// The map marker associated with the map view controller.
    var mapMarker: MapMarker?

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        locationManager.delegate = self

        // Request a user’s location once
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()

        // Load the map scene using a map scheme to render the map with.
        mapView.mapScene.loadScene(mapScheme: MapScheme.normalDay, completion: onLoadScene)
    }

    // MARK: - configureMapView

    // Completion handler when loading a map scene.
    private func onLoadScene(mapError: MapError?) {
        guard mapError == nil else {
            print("Error: Map scene not loaded, \(String(describing: mapError))")
            return
        }

        mapApp = MapApp(viewController: self, mapView: mapView!, messageTextView: UITextView())

        // Configure the map.
        let camera = mapView.camera
        let distanceInMeters = MapMeasure(kind: .distance, value: 1000 * 10)
        camera.lookAt(point: GeoCoordinates(latitude: 52.518043, longitude: 13.405991), zoom: distanceInMeters)

//        mapApp.addRouteSimulatedLocationButtonClicked()
    }

    func locationManager(
        _: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        if let location = locations.first {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            // Handle location update
            return;
            let geoCoordinates = GeoCoordinates(latitude: latitude, longitude: longitude)

            if mapMarker == nil {
                let camera = mapView.camera
                let distanceInMeters = MapMeasure(kind: .distance, value: 800 * 10)
                camera.lookAt(point: geoCoordinates, zoom: distanceInMeters)

                let locationMarkerSize = Int32(30 * mapView.pixelScale)
                let anchor = Anchor2D(horizontal: 0.5, vertical: 1)
                //                let mapImage = try! MapImage(named: "position", width: locationMarkerSize, height: locationMarkerSize)
                let mapImage = try! MapImage(from: UIImage(named: "position")!)!

                mapMarker = MapMarker(at: geoCoordinates, image: mapImage, anchor: anchor)
                mapView.mapScene.addMapMarker(mapMarker!)
            } else {
                mapMarker?.coordinates = geoCoordinates
                mapView.camera.lookAt(point: geoCoordinates)
            }
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error)")
    }
//
//
//    func beginNavigation() {
//
//      let geoCode1 = GeoCoordinates(latitude: 52.518043, longitude: 13.405991)
//        let geoCode2 = GeoCoordinates(latitude: 52.235555, longitude: 13.41213)
//
//        let wayPointDepart = Waypoint(coordinates: geoCode1)
//        let wayPointDestination = Waypoint(coordinates: geoCode2)
//
//        let routingEngine = try! RoutingEngine();
//        routingEngine.calculateRoute(with: [wayPointDepart, wayPointDestination], carOptions: CarOptions(routeOptions: RouteOptions()), completion: {error,routes in
//            debugPrint(routes ?? "");
//
//            if let route = routes?.first {
//                let lineColor = UIColor(red: 0, green: 0.56, blue: 0.54, alpha: 0.63)
//                let widthInPixels = 20.0
//
//                let routeMapPolyline = MapPolyline(geometry: route.geometry, representation: try! MapPolyline.SolidRepresentation(
//                    lineWidth: try! MapMeasureDependentRenderSize(
//                        sizeUnit: RenderSize.Unit.pixels,
//                        size: widthInPixels),
//                    color: lineColor,
//                    capShape: LineCap.round))
//
//                self.mapView.mapScene.addMapPolyline(routeMapPolyline)
//                self.mapView.camera.lookAt(point: geoCode1)
//
//                let simulator = try! LocationSimulator(route: route, options: LocationSimulatorOptions())
//                simulator.start()
//            }
//        })
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
