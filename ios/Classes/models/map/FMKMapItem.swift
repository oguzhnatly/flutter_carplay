import MapKit

/// A wrapper class for MKMapItem with additional functionality.

@available(iOS 14.0, *)
class FMKMapItem {
    /// The underlying MKMapItem instance.
    private(set) var _super: MKMapItem?

    /// The unique identifier for the map item.
    private(set) var elementId: String

    /// latitude and longitude
    private(set) var latitude: Double
    private(set) var longitude: Double

    /// The name of the map item
    private(set) var name: String?

    /// Initializes an instance of FMKMapItem with the provided parameters.
    /// - Parameter obj:
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String else {
            fatalError("Missing required key: _elementId")
        }
        elementId = elementIdValue

        latitude = obj["latitude"] as? Double ?? 0
        longitude = obj["longitude"] as? Double ?? 0
        name = obj["name"] as? String
    }

    /// Returns the MKMapItem instance.
    var get: MKMapItem {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
        mapItem.name = name
        _super? = mapItem
        return mapItem
    }
}
