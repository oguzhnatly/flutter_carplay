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
    private var title:String
    private var subtitle:String?
    private var summary:String?
    private var detailTitle:String?
    private var detailSubtitle:String?
    private var detailSummary:String?
    private var image:String?
    
    private var primaryButton: CPTextButton?
    private var objcPrimaryButton: FCPTextButton?
    
    private var secondaryButton: CPTextButton?
    private var objcSecondaryButton: FCPTextButton?
    
    
    
    static let maxPinImageSize:CGFloat = 40
    
    init(obj: [String : Any]) {
        self.elementId = obj["_elementId"] as! String
        
        let lat =  obj["latitude"] as! NSNumber
        self.latitude = lat.doubleValue
        
        let lng = obj["longitude"] as! NSNumber
        self.longitude = lng.doubleValue
        self.title = obj["title"] as! String
        self.subtitle = obj["subtitle"] as? String
        self.summary = obj["summary"] as? String
        self.detailTitle = obj["detailTitle"] as? String
        self.detailSubtitle = obj["detailSubtitle"] as? String
        self.detailSummary = obj["detailSummary"] as? String
        self.image = obj["image"] as? String
        
        
      
        let primaryButtonData = obj["primaryButton"] as? [String : Any]
        if primaryButtonData != nil {
            self.objcPrimaryButton = FCPTextButton(obj: primaryButtonData!);
            self.primaryButton = self.objcPrimaryButton?.get
        
        }
  
        
        let secondaryButtonData = obj["secondaryButton"] as? [String : Any]
        if secondaryButtonData != nil {
            self.objcSecondaryButton = FCPTextButton(obj: secondaryButtonData!);
            self.secondaryButton = self.objcSecondaryButton?.get
        }
    }
    
    var get: CPPointOfInterest {
        
        let location = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
        var pinImage:UIImage? = nil;
        
        if let image = self.image {
            let key = SwiftFlutterCarplayPlugin.registrar?.lookupKey(forAsset: image)
            
            pinImage = UIImage(named: key!)
            if let pImage = pinImage {
                if pImage.size.height > FCPPointOfInterest.maxPinImageSize  ||
                    pImage.size.width > FCPPointOfInterest.maxPinImageSize {
                    pinImage = pImage.resizeImageTo(size: CGSize(width:FCPPointOfInterest.maxPinImageSize,height:FCPPointOfInterest.maxPinImageSize))
                }
            }
        }
        let poi = CPPointOfInterest(location:location,title:title,subtitle: subtitle,summary:summary,
                                    detailTitle:detailTitle,detailSubtitle: detailSubtitle,
                                    detailSummary: detailSummary,pinImage: pinImage);
        
        if let primaryButton = self.primaryButton {
            poi.primaryButton = primaryButton
      
        }
        if let secondaryButton = self.secondaryButton {
            poi.secondaryButton = secondaryButton
        }
        
        self._super = poi
        return poi
    }
}
