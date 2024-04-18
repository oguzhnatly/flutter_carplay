//
//  FCPPointOfInterest.swift
//  Runner
//
//  Created by Olaf Schneider on 15.02.22.
//

import CarPlay

@available(iOS 14.0, *)
class FCPPointOfInterest {
    private(set) var _super: CPPointOfInterest?
    private(set) var elementId: String
    private var latitude: Double
    private var longitude: Double
    private var title: String
    private var subtitle: String?
    private var summary: String?
    private var detailTitle: String?
    private var detailSubtitle: String?
    private var detailSummary: String?
    private var image: String?

    private var primaryButton: CPTextButton?
    private var objcPrimaryButton: FCPTextButton?

    private var secondaryButton: CPTextButton?
    private var objcSecondaryButton: FCPTextButton?

    static let maxPinImageSize: CGFloat = 40

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String

        let lat = obj["latitude"] as! NSNumber
        latitude = lat.doubleValue

        let lng = obj["longitude"] as! NSNumber
        longitude = lng.doubleValue
        title = obj["title"] as! String
        subtitle = obj["subtitle"] as? String
        summary = obj["summary"] as? String
        detailTitle = obj["detailTitle"] as? String
        detailSubtitle = obj["detailSubtitle"] as? String
        detailSummary = obj["detailSummary"] as? String
        image = obj["image"] as? String

        let primaryButtonData = obj["primaryButton"] as? [String: Any]
        if primaryButtonData != nil {
            objcPrimaryButton = FCPTextButton(obj: primaryButtonData!)
            primaryButton = objcPrimaryButton?.get
        }

        let secondaryButtonData = obj["secondaryButton"] as? [String: Any]
        if secondaryButtonData != nil {
            objcSecondaryButton = FCPTextButton(obj: secondaryButtonData!)
            secondaryButton = objcSecondaryButton?.get
        }
    }

    var get: CPPointOfInterest {
        let location = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
        var pinImage: UIImage? = nil

        if let image = image {
            let key = SwiftFlutterCarplayPlugin.registrar?.lookupKey(forAsset: image)

            pinImage = UIImage(named: key!)
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
