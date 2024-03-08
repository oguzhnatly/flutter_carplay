//// A wrapper class for CPRouteChoice with additional functionality.
import CarPlay

@available(iOS 14.0, *)
class FCPRouteChoice {
    /// The underlying CPRouteChoice instance.
    private(set) var _super: CPRouteChoice?

    /// The unique identifier for the bar button.
    private(set) var elementId: String

    /// summaryVariants is an array of summary variants for this route choice
    private(set) var summaryVariants: [String]?

    /// selectionSummaryVariants is an array of selection summary variants
    /// for this route choice
    private(set) var selectionSummaryVariants: [String]?

    /// additionalInformationVariants is an array of additional information
    /// variants for this route choice
    private(set) var additionalInformationVariants: [String]?

    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String else {
            fatalError("Missing required key: _elementId")
        }
        elementId = elementIdValue

        summaryVariants = obj["summaryVariants"] as? [String]
        selectionSummaryVariants = obj["selectionSummaryVariants"] as? [String]
        additionalInformationVariants = obj["additionalInformationVariants"] as? [String]
    }

    /// Get the underlying CPRouteChoice
    var get: CPRouteChoice {
        let route = CPRouteChoice(summaryVariants: summaryVariants ?? [],
                                  additionalInformationVariants: additionalInformationVariants ?? [],
                                  selectionSummaryVariants: selectionSummaryVariants ?? [])
        _super = route

        return route
    }
}
