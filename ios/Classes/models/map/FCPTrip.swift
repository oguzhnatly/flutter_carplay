import CarPlay

/// A wrapper class for CPTrip with additional functionality.
@available(iOS 14.0, *)
class FCPTrip {
    /// The underlying CPTrip instance.
    private(set) var _super: CPTrip?

    /// The unique identifier for the bar button.
    private(set) var elementId: String

    // The origin and destination
    private(set) var origin: FMKMapItem
    private(set) var destination: FMKMapItem

    // The route choices
    private(set) var routeChoices: [FCPRouteChoice]

    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String,
              let originValue = obj["origin"] as? [String: Any],
              let destinationValue = obj["destination"] as? [String: Any]
        else {
            fatalError("Missing required key")
        }
        elementId = elementIdValue
        origin = FMKMapItem(obj: originValue)
        destination = FMKMapItem(obj: destinationValue)
        routeChoices = (obj["routeChoices"] as? [[String: Any]] ?? []).map {
            FCPRouteChoice(obj: $0)
        }
    }

    /// Returns the CPTrip instance.
    var get: CPTrip {
        let trip = CPTrip(origin: origin.get, destination: destination.get, routeChoices: routeChoices.map { $0.get })
        _super = trip
        return trip
    }
}
