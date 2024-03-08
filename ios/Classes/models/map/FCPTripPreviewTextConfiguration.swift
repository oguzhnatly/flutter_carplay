import CarPlay

/// A wrapper class for CPTripPreviewTextConfiguration with additional functionality.
@available(iOS 14.0, *)
class FCPTripPreviewTextConfiguration {
    /// The underlying CPTripPreviewTextConfiguration instance.
    private(set) var _super: CPTripPreviewTextConfiguration?

    /// The unique identifier for the map template.
    private(set) var elementId: String

    /// The title of the start button.
    private(set) var startButtonTitle: String?

    /// The title of the additional routes button.
    private(set) var additionalRoutesButtonTitle: String?

    /// The title of the overview button.
    private(set) var overviewButtonTitle: String?

    /// Initializes an instance of FCPTripPreviewTextConfiguration with the provided parameters.
    /// - Parameter obj:
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String else {
            fatalError("Missing required key: _elementId")
        }
        elementId = elementIdValue

        startButtonTitle = obj["startButtonTitle"] as? String
        additionalRoutesButtonTitle = obj["additionalRoutesButtonTitle"] as? String
        overviewButtonTitle = obj["overviewButtonTitle"] as? String
    }

    /// Returns the CPTripPreviewTextConfiguration instance.
    var get: CPTripPreviewTextConfiguration {
        let superCPTripPreviewTextConfiguration = CPTripPreviewTextConfiguration(
            startButtonTitle: startButtonTitle,
            additionalRoutesButtonTitle: additionalRoutesButtonTitle,
            overviewButtonTitle: overviewButtonTitle
        )
        _super = superCPTripPreviewTextConfiguration

        return superCPTripPreviewTextConfiguration
    }
}
