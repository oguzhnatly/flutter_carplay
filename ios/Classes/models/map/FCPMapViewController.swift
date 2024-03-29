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

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        // Load the map scene using a map scheme to render the map with.
        mapView.mapScene.loadScene(mapScheme: MapScheme.normalDay, completion: onLoadScene)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        let scale = FlutterCarPlaySceneDelegate.carWindow?.screen.scale ?? 1.0
        let topSafeArea = view.safeAreaInsets.top * scale
        let leftSafeArea = view.safeAreaInsets.left * scale
        let rightSafeArea = view.safeAreaInsets.right * scale
        let width = view.bounds.width * scale
        let height = view.bounds.height * scale
        let bannerHeight = bannerView.bounds.height
        
        mapView.camera.principalPoint = Point2D(x: leftSafeArea + (width - leftSafeArea - rightSafeArea)/2.0, y: topSafeArea + bannerHeight + (height - topSafeArea - bannerHeight)/2.0)
    }

    // MARK: - configureMapView

    // Completion handler when loading a map scene.
    private func onLoadScene(mapError: MapError?) {
        guard mapError == nil else {
            print("Error: Map scene not loaded, \(String(describing: mapError))")
            return
        }

        mapController = MapController(viewController: self, mapView: mapView!, messageTextView: UITextView())

        
    }
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
        return
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
    func showInitialMarkerOnMap(coordinates: GeoCoordinates, accuracy: Double) {
        let metadata = heresdk.Metadata()
        metadata.setString(key: "marker", value: "initial_marker")
        metadata.setString(key: "polygon", value: "initial_marker")

        let image = UIImage().fromFlutterAsset(name: "assets/icons/car_play/position.png")

        let markerSize = 30 * mapView.pixelScale;
        mapController?.addMapMarker(coordinates: coordinates, markerImage: image, markerSize: CGSize(width: markerSize, height: markerSize), metadata: metadata)
        mapController?.addMapPolygon(coordinate: coordinates, accuracy: accuracy, metadata: metadata)
        
        mapView.camera.lookAt(point: coordinates, zoom: MapMeasure(kind: .distance, value: 8000.0))
    }

    /// Adds a destination marker on the map.
    /// - Parameters:
    ///   - coordinates: The coordinates of the marker
    ///   - accuracy: The accuracy of the marker
    func destinationAddressUpdatedOnMap(coordinates: GeoCoordinates, accuracy _: Double) {
        let metadata = heresdk.Metadata()
        metadata.setString(key: "marker", value: "destination_marker")

        let image = UIImage().fromFlutterAsset(name: "assets/icons/car_play/map_marker_wp.png")
        
        let markerSize = 49 * mapView.pixelScale;
        mapController?.addMapMarker(coordinates: coordinates, markerImage: image, markerSize: CGSize(width: markerSize, height: markerSize), metadata: metadata)
        
//        let safearea = FlutterCarPlaySceneDelegate.carWindow?.safeAreaInsets ?? UIEdgeInsets.zero
//        
//        print("safeArea: \(String(describing: FlutterCarPlaySceneDelegate.carWindow?.safeAreaInsets))")
//        print("safeArea from view: \(String(describing: view.safeAreaInsets))")
        let width = view.bounds.width
        let height = view.bounds.height
        let bannerHeight = bannerView.bounds.height
//        
//        mapView.camera.principalPoint = Point2D(x: width/2.0, y: height/2.0)
        
        mapView.camera.lookAt(point: coordinates, zoom: MapMeasure(kind: .distance, value: 8000.0))
    }

    /// Starts the navigation
    /// - Parameter destination: The destination waypoint
    func startNavigation(trip: CPTrip) {
        let wayPoint = Waypoint(coordinates: GeoCoordinates(latitude: trip.destination.placemark.coordinate.latitude, longitude: trip.destination.placemark.coordinate.longitude))
        mapController?.setDestinationWaypoint(wayPoint)

        mapController?.addRouteSimulatedLocationButtonClicked()
    }

    /// Stops the navigation
    func stopNavigation() {
        mapController?.clearMapButtonClicked()
    }
}
