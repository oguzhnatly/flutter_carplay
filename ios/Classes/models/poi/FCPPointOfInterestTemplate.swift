//
//  FCPPointOfInterestTemplate.swift
//  flutter_carplay
//
//  Created by Olaf Schneider on 15.02.22.
//

import CarPlay

/// A custom template for displaying points of interest on CarPlay maps.
@available(iOS 14.0, *)
class FCPPointOfInterestTemplate {
    // MARK: Properties

    /// The underlying CPPointOfInterestTemplate instance.
    private(set) var _super: CPPointOfInterestTemplate?

    /// The unique identifier for the point of interest template.
    private(set) var elementId: String

    /// The title of the point of interest template.
    private var title: String

    /// The list of points of interest associated with the template.
    private var poi: [FCPPointOfInterest]

    // MARK: Initialization

    /// Initializes a new instance of `FCPPointOfInterestTemplate` with the specified parameters.
    ///
    /// - Parameter obj: A dictionary containing the properties of the point of interest template.
    init(obj: [String: Any]) {
        guard let elementId = obj["_elementId"] as? String,
              let title = obj["title"] as? String,
              let poiArray = obj["poi"] as? [[String: Any]]
        else {
            fatalError("Missing required properties for FCPPointOfInterestTemplate initialization.")
        }

        self.elementId = elementId
        self.title = title
        poi = poiArray.compactMap { FCPPointOfInterest(obj: $0) }
    }

    // MARK: Methods

    /// Returns a `CPPointOfInterestTemplate` object representing the point of interest template.
    ///
    /// - Returns: A `CPPointOfInterestTemplate` object.
    var get: CPPointOfInterestTemplate {
        var pois: [CPPointOfInterest] = []

        for p in poi {
            pois.append(p.get)
        }

        let pointOfInterestTemplate = CPPointOfInterestTemplate(title: title, pointsOfInterest: pois, selectedIndex: NSNotFound)
        pointOfInterestTemplate.setFCPObject(self)
        _super = pointOfInterestTemplate
        return pointOfInterestTemplate
    }
}

@available(iOS 14.0, *)
extension FCPPointOfInterestTemplate: FCPRootTemplate {}

@available(iOS 14.0, *)
extension FCPPointOfInterestTemplate: FCPTemplate {}
