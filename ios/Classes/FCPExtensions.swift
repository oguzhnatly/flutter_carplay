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
            return image ?? UIImage(systemName: "questionmark") ?? UIImage()
        }
        return UIImage()
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
