//
//  FCPPointOfInterest.swift
//  Runner
//
//  Created by Olaf Schneider on 15.02.22.
//

import CarPlay
import MapKit

/// A custom point of interest (POI) class for use with CarPlay maps.
@available(iOS 14.0, *)
class FCPPointOfInterest {
    // MARK: Properties

    /// The underlying CPPointOfInterest instance.
    private(set) var _super: CPPointOfInterest?

    /// The unique identifier for the point of interest.
    private(set) var elementId: String

    /// The latitude of the point of interest.
    private var latitude: Double

    /// The longitude of the point of interest.
    private var longitude: Double

    /// The title of the point of interest.
    private var title: String

    /// The subtitle of the point of interest.
    private var subtitle: String?

    /// The summary of the point of interest.
    private var summary: String?

    /// The detailed title of the point of interest.
    private var detailTitle: String?

    /// The detailed subtitle of the point of interest.
    private var detailSubtitle: String?

    /// The detailed summary of the point of interest.
    private var detailSummary: String?

    /// The image associated with the point of interest.
    private var image: String?

    /// The primary button associated with the point of interest.
    private var primaryButton: CPTextButton?

    /// The FCP object of the primary button associated with the point of interest.
    private var objcPrimaryButton: FCPTextButton?

    /// The secondary button associated with the point of interest.
    private var secondaryButton: CPTextButton?

    /// The Fcp object of the secondary button associated with the point of interest.
    private var objcSecondaryButton: FCPTextButton?

    /// The maximum size for the pin image.
    static let maxPinImageSize: CGFloat = 40

    // MARK: Initialization

    /// Initializes a new instance of `FCPPointOfInterest` with the specified parameters.
    ///
    /// - Parameter obj: A dictionary containing the properties of the point of interest.
    init(obj: [String: Any]) {
        guard let elementId = obj["_elementId"] as? String,
              let latitudeNumber = obj["latitude"] as? NSNumber,
              let longitudeNumber = obj["longitude"] as? NSNumber,
              let title = obj["title"] as? String
        else {
            fatalError("Missing required properties for FCPPointOfInterest initialization.")
        }

        self.elementId = elementId
        latitude = latitudeNumber.doubleValue
        longitude = longitudeNumber.doubleValue
        self.title = title
        subtitle = obj["subtitle"] as? String
        summary = obj["summary"] as? String
        detailTitle = obj["detailTitle"] as? String
        detailSubtitle = obj["detailSubtitle"] as? String
        detailSummary = obj["detailSummary"] as? String
        image = obj["image"] as? String

        if let primaryButtonData = obj["primaryButton"] as? [String: Any] {
            objcPrimaryButton = FCPTextButton(obj: primaryButtonData)
            primaryButton = objcPrimaryButton?.get
        }

        if let secondaryButtonData = obj["secondaryButton"] as? [String: Any] {
            objcSecondaryButton = FCPTextButton(obj: secondaryButtonData)
            secondaryButton = objcSecondaryButton?.get
        }
    }

    // MARK: Methods

    /// Returns a `CPPointOfInterest` object representing the point of interest.
    ///
    /// - Returns: A `CPPointOfInterest` object.
    var get: CPPointOfInterest {
        let location = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
        var pinImage: UIImage? = nil

        if let image = image,
           let key = SwiftFlutterCarplayPlugin.registrar?.lookupKey(forAsset: image)
        {
            pinImage = UIImage(named: key)
            if let pImage = pinImage {
                if pImage.size.height > FCPPointOfInterest.maxPinImageSize ||
                    pImage.size.width > FCPPointOfInterest.maxPinImageSize
                {
                    pinImage = pImage.resizeImageTo(size: CGSize(width: FCPPointOfInterest.maxPinImageSize, height: FCPPointOfInterest.maxPinImageSize))
                }
            }
        }
        let poi = CPPointOfInterest(location: location, title: title, subtitle: subtitle, summary: summary,
                                    detailTitle: detailTitle, detailSubtitle: detailSubtitle,
                                    detailSummary: detailSummary, pinImage: pinImage)

        if let primaryButton = primaryButton {
            poi.primaryButton = primaryButton
        }
        if let secondaryButton = secondaryButton {
            poi.secondaryButton = secondaryButton
        }
        _super = poi
        return poi
    }
}
