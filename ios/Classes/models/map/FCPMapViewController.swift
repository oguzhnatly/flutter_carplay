import CarPlay
import Foundation
import MapKit
import UIKit

@available(iOS 14.0, *)
class FCPMapViewController: UIViewController, CPMapTemplateDelegate {
    var mapView: MKMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
    }

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

    func mapTemplateDidBeginPanGesture(_: CPMapTemplate) {
        print("🚙🚙🚙🚙🚙 Panning")
    }

    func mapTemplate(_: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        print("🚙🚙🚙🚙🚙 Panning: \(direction)")
    }

    func mapTemplate(_: CPMapTemplate, buttonPressed button: CPBarButton) {
        if button.title == "Location" { // Replace with the actual button title
            calculateAndDisplayRoute()
        }
    }

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
                print("Route calculation failed.")
                return
            }

            self.mapView?.removeOverlays(self.mapView?.overlays ?? [])
            self.mapView?.addOverlay(route.polyline, level: .aboveRoads)

            let routeRect = route.polyline.boundingMapRect
            self.mapView?.setRegion(MKCoordinateRegion(routeRect), animated: true)
        }
    }
}

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
