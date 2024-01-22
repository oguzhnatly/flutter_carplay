//
//  FCPExtensions.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

/// Convenience initializer for creating a UIImage from a URL.
/// - Parameter url: The URL of the image.
/// - Throws: An error if there is an issue with retrieving or initializing the image data.
extension UIImage {
    convenience init?(withURL url: URL) throws {
        let imageData = try Data(contentsOf: url)
        self.init(data: imageData)
    }

    /// Fetches a UIImage from a Flutter asset using the asset name.
    /// - Parameter name: The name of the Flutter asset.
    /// - Returns: A UIImage fetched from the Flutter asset or a system image if not found.
    @available(iOS 14.0, *)
    func fromFlutterAsset(name: String) -> UIImage {
        if let key = SwiftFlutterCarplayPlugin.registrar?.lookupKey(forAsset: name) {
            let image = UIImage(imageLiteralResourceName: key)
            return image
        }
        return UIImage(systemName: "questionmark") ?? UIImage()
    }

    /// Resizes the current UIImage to the specified size.
    /// - Parameter size: The target size for the resized image.
    /// - Returns: The resized UIImage or nil if resizing fails.
    func resizeImageTo(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return newImage
        }
        return nil
    }
}

/// Extension on String providing a method to match a regular expression.
extension String {
    /// Matches the string against a regular expression pattern.
    /// - Parameter regex: The regular expression pattern.
    /// - Returns: An array of matched substrings.
    func match(_ regex: String) -> [[String]] {
        let nsString = self as NSString
        return (try? NSRegularExpression(pattern: regex, options: []))?.matches(in: self, options: [], range: NSMakeRange(0, nsString.length)).map { match in
            (0 ..< match.numberOfRanges).map { match.range(at: $0).location == NSNotFound ? "" : nsString.substring(with: match.range(at: $0)) }
        } ?? []
    }
}

/// Extension on CPTemplate to set a custom FCPTemplate object in its userInfo.
extension CPTemplate {
    /// Sets a custom FCPTemplate object in the userInfo.
    /// - Parameter template: The FCPTemplate object to be associated with the CPTemplate.
    func setFCPObject(_ template: FCPTemplate) {
        userInfo = ["FCPObject": template]
    }
}

/// Extension on CPListItem to set a custom FCPListItem object in its userInfo.
extension CPListItem {
    /// Sets a custom FCPListItem object in the userInfo.
    /// - Parameter item: The FCPListItem object to be associated with the CPListItem.
    func setFCPObject(_ item: FCPListItem) {
        userInfo = ["FCPObject": item]
    }
}

/// Extension on UIColor to create a UIColor from RGB values.
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        assert(alpha >= 0 && alpha <= 1.0, "Invalid alpha component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }

    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }

    convenience init(argb: Int) {
        self.init(
            red: (argb >> 16) & 0xFF,
            green: (argb >> 8) & 0xFF,
            blue: argb & 0xFF,
            alpha: CGFloat((argb >> 24) & 0xFF) / 255.0
        )
    }
}

/// Extension on UIView to fix a view in a container view.
extension UIView {
    func fixInView(_ container: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        frame = container.frame
        container.addSubview(self)
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}
