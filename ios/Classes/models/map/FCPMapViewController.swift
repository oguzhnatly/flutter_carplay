import CarPlay
import Foundation
import MapKit
import UIKit

/// FCPMapViewController is a class that represents a view controller with a map for CarPlay.
@available(iOS 14.0, *)
class FCPMapViewController: UIViewController, CPMapTemplateDelegate {
    /// The map view used in the controller.
    var mapView: MKMapView?

    /// The banner view used in the controller.
    var bannerView: FCPBannerView?

    /// The toast view used in the controller.
    var toastView: FCPToastView?

    /// This method is called after the controller's view is loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
    }

    /// This method is called when the view's bounds change.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //        showToast(message: "This is a toast message")
        //        showBanner(message: "This is a toast message")
    }

    /// Sets up the map view and its constraints.
    private func setupMapView() {
        mapView = MKMapView(frame: view.bounds)
        mapView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView!)

        mapView?.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mapView?.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        mapView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mapView?.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true

        configureMapView()
    }

    /// Configures the settings for the map view.
    private func configureMapView() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 23.0225, longitude: 72.5714),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )

        mapView?.setRegion(region, animated: true)
        mapView?.showsUserLocation = true
        mapView?.delegate = self // Add this line
        mapView?.setUserTrackingMode(.follow, animated: true)
        mapView?.overrideUserInterfaceStyle = .light
    }

    // Implement CPMapTemplateDelegate methods here
    // ...

    /// Called when a pan gesture begins on the map.
    func mapTemplateDidBeginPanGesture(_: CPMapTemplate) {
        MemoryLogger.shared.appendEvent("🚙🚙🚙🚙🚙 Panning")
    }

    /// Called when the map is panned in a specific direction.
    func mapTemplate(_: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        MemoryLogger.shared.appendEvent("🚙🚙🚙🚙🚙 Panning: \(direction)")
    }

    /// Called when a button is pressed on the map template.
    func mapTemplate(_: CPMapTemplate, buttonPressed button: CPBarButton) {
        if button.title == "Location" { // Replace with the actual button title
            calculateAndDisplayRoute()
        }
    }

    /// Calculates and displays a route on the map.
    func calculateAndDisplayRoute() {
        // Replace these coordinates with the actual destination coordinates
        let sourceLocation = CLLocationCoordinate2D(latitude: 22.9978, longitude: 72.6660)
        let destinationLocation = CLLocationCoordinate2D(latitude: 23.0120, longitude: 72.5108)

        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation)
        let destinationPlacemark = MKPlacemark(coordinate: destinationLocation)

        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile

        let directions = MKDirections(request: directionRequest)
        directions.calculate { response, _ in
            guard let route = response?.routes.first else {
                MemoryLogger.shared.appendEvent("Route calculation failed.")
                return
            }

            self.mapView?.removeOverlays(self.mapView?.overlays ?? [])
            self.mapView?.addOverlay(route.polyline, level: .aboveRoads)

            let routeRect = route.polyline.boundingMapRect
            self.mapView?.setRegion(MKCoordinateRegion(routeRect), animated: true)
        }
    }
}

// Extension for MKMapViewDelegate methods
extension FCPMapViewController: MKMapViewDelegate {
    func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}

// Extension for UIViewController utility methods
extension FCPMapViewController {
    /// Displays a banner message at the top of the screen for a specified duration.
    func showBanner(message: String, color: Int) {
        bannerView?.removeFromSuperview()
        bannerView = FCPBannerView(frame: CGRect(x: 0, y: 44, width: view.bounds.width, height: 32))

        debugPrint("mapView center: \(mapView!.center)")
        debugPrint("mapView width: \(mapView!.frame.width)")
        debugPrint("mapView height: \(mapView!.frame.height)")

        if let bannerView = bannerView {
            bannerView.messageLabel.text = message
            bannerView.backgroundColor = UIColor(argb: color)
            view.addSubview(bannerView)
        }
    }

    /// Hides the banner message at the top of the screen.
    func hideBanner() {
        bannerView?.removeFromSuperview()
        bannerView = nil
    }

    /// Displays a toast message on the screen for a specified duration.
    func showToast(message: String, duration: TimeInterval = 2.0) {
        toastView?.removeFromSuperview()

        let textSize = UILabel.textSize(font: UIFont.systemFont(ofSize: 14), text: message, width: view.bounds.width - 80, height: 100)

        toastView = FCPToastView(frame: CGRect(x: (view.bounds.width / 2) - (textSize.width / 2), y: view.bounds.height - (textSize.height + 40), width: textSize.width + 24, height: textSize.height + 24))

        if let toastView = toastView {
            toastView.messageLabel.text = message

            view.addSubview(toastView)

            UIView.animate(withDuration: 0.5, delay: duration, options: .curveEaseOut, animations: {
                toastView.alpha = 0.0
            }, completion: { _ in
                toastView.removeFromSuperview()
            })
        }
    }
}
