//
//  FCPExtensions.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import ImageIO

/// Returns true if lhs is less than rhs.
private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

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
        guard let key = SwiftFlutterCarplayPlugin.registrar?.lookupKey(forAsset: name),
              let path = Bundle.main.path(forResource: key, ofType: nil),
              let image = UIImage(contentsOfFile: path)
        else {
            MemoryLogger.shared.appendEvent("image \"\(name)\" not found")
            return UIImage(systemName: "questionmark") ?? UIImage()
        }

        // Check if the asset is a GIF
        if name.hasSuffix(".gif"), let gifData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return UIImage.gifImageWithData(gifData) ?? UIImage()
        }

        return image
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

    /// Creates an animated UIImage from the provided CGImageSource.
    /// - Parameter data: The data of the CGImageSource
    /// - Returns: An animated UIImage
    public class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            MemoryLogger.shared.appendEvent("image doesn't exist")
            return nil
        }

        return UIImage.animatedImageWithSource(source)
    }

    /// Creates an animated UIImage from the provided URL.
    /// - Parameter gifUrl: The URL of the GIF
    /// - Returns: An animated UIImage
    public class func gifImageWithURL(_ gifUrl: String) -> UIImage? {
        guard let bundleURL = URL(string: gifUrl)
        else {
            MemoryLogger.shared.appendEvent("image named \"\(gifUrl)\" doesn't exist")
            return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            MemoryLogger.shared.appendEvent("SwiftGif: Cannot turn image named \"\(gifUrl)\" into NSData")
            return nil
        }

        return gifImageWithData(imageData)
    }

    /// Creates an animated UIImage from the provided name.
    /// - Parameter name: The name of the GIF
    /// - Returns: An animated UIImage
    public class func gifImageWithName(_ name: String) -> UIImage? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif")
        else {
            MemoryLogger.shared.appendEvent("SwiftGif: This image named \"\(name)\" does not exist")
            return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            MemoryLogger.shared.appendEvent("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }

        return gifImageWithData(imageData)
    }

    /// Calculates the duration of an image in the source.
    /// - Parameter index: The index of the image
    /// - Parameter source: The source of the image
    /// - Returns: The duration of the image
    class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1

        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self
        )

        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self
        )
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }

        delay = delayObject as! Double

        if delay < 0.1 {
            delay = 0.1
        }

        return delay
    }

    /// Calculates the gcd of two integers
    /// - Parameter a: The first integer
    /// - Parameter b: The second integer
    /// - Returns: The gcd
    class func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }

        if a < b {
            let c = a
            a = b
            b = c
        }

        var rest: Int
        while true {
            rest = a! % b!

            if rest == 0 {
                return b!
            } else {
                a = b
                b = rest
            }
        }
    }

    /// Calculates the gcd of an array of integers
    /// - Parameter array: The array of integers
    /// - Returns: The gcd
    class func gcdForArray(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }

        var gcd = array[0]

        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }

        return gcd
    }

    /// Creates an animated UIImage from the provided source
    /// - Parameter source: The source of the image
    /// - Returns: An animated UIImage
    class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()

        for i in 0 ..< count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }

            let delaySeconds = UIImage.delayForImageAtIndex(Int(i),
                                                            source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }

        let duration: Int = {
            var sum = 0

            for val: Int in delays {
                sum += val
            }

            return sum
        }()

        let gcd = gcdForArray(delays)
        var frames = [UIImage]()

        var frame: UIImage
        var frameCount: Int
        for i in 0 ..< count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)

            for _ in 0 ..< frameCount {
                frames.append(frame)
            }
        }

        let animation = UIImage.animatedImage(with: frames,
                                              duration: Double(duration) / 1000.0)

        return animation
    }

    /// Apply color tint to image.
    /// - Parameter color: The color to apply
    /// - Returns: The tinted image
    func withColor(_ color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        let drawRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        color.setFill()
        UIRectFill(drawRect)

        draw(in: drawRect, blendMode: .destinationIn, alpha: 1)

        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage!
    }

    /// Creates a dynamic image that supports displaying a different image asset when dark mode is active.
    private static func dynamicImageWith(
        light makeLight: @autoclosure () -> UIImage,
        light2x makeLight2x: @autoclosure () -> UIImage? = nil,
        light3x makeLight3x: @autoclosure () -> UIImage? = nil,
        dark makeDark: @autoclosure () -> UIImage,
        dark2x makeDark2x: @autoclosure () -> UIImage? = nil,
        dark3x makeDark3x: @autoclosure () -> UIImage? = nil
    ) -> UIImage {
        // Register light mode image with light trait
        let image = UITraitCollection(userInterfaceStyle: .light).makeImage(makeLight())

        // Register dark mode image with dark trait
        image.imageAsset?.register(makeDark(), with: UITraitCollection(userInterfaceStyle: .dark))

        // Register @2x and @3x images for light mode if provided
        if let light2xImage = makeLight2x() {
            image.imageAsset?.register(light2xImage, with: UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .light),
                UITraitCollection(displayScale: 2),
            ]))
        }

        if let light3xImage = makeLight3x() {
            image.imageAsset?.register(light3xImage, with: UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .light),
                UITraitCollection(displayScale: 3),
            ]))
        }

        // Register @2x and @3x images for dark mode if provided
        if let dark2xImage = makeDark2x() {
            image.imageAsset?.register(dark2xImage, with: UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .dark),
                UITraitCollection(displayScale: 2),
            ]))
        }

        if let dark3xImage = makeDark3x() {
            image.imageAsset?.register(dark3xImage, with: UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .dark),
                UITraitCollection(displayScale: 3),
            ]))
        }

        return image
    }

    /// Get dynamic theme image
    /// - Parameter lightImage: The image name for light mode
    /// - Parameter darkImage: The image name for dark mode
    /// - Returns: The UIImage
    static func dynamicImage(lightImage: String? = nil, darkImage: String? = nil) -> UIImage? {
        if let lightImage = lightImage,
           let darkImage = darkImage
        {
            return UIImage.dynamicImageWith(
                light: UIImage().fromFlutterAsset(name: lightImage),
                light2x: UIImage().fromFlutterAsset(name: lightImage.replacingLastOccurrenceOfString(".png", with: "@2x.png")),
                light3x: UIImage().fromFlutterAsset(name: lightImage.replacingLastOccurrenceOfString(".png", with: "@3x.png")),
                dark: UIImage().fromFlutterAsset(name: darkImage),
                dark2x: UIImage().fromFlutterAsset(name: darkImage.replacingLastOccurrenceOfString(".png", with: "@2x.png")),
                dark3x: UIImage().fromFlutterAsset(name: darkImage.replacingLastOccurrenceOfString(".png", with: "@3x.png"))
            )
        } else if let lightImage = lightImage {
            return UIImage.dynamicImageWith(
                light: UIImage().fromFlutterAsset(name: lightImage),
                light2x: UIImage().fromFlutterAsset(name: lightImage.replacingLastOccurrenceOfString(".png", with: "@2x.png")),
                light3x: UIImage().fromFlutterAsset(name: lightImage.replacingLastOccurrenceOfString(".png", with: "@3x.png")),
                dark: UIImage()
            )
        } else if let darkImage = darkImage {
            return UIImage.dynamicImageWith(
                light: UIImage(),
                dark: UIImage().fromFlutterAsset(name: darkImage),
                dark2x: UIImage().fromFlutterAsset(name: darkImage.replacingLastOccurrenceOfString(".png", with: "@2x.png")),
                dark3x: UIImage().fromFlutterAsset(name: darkImage.replacingLastOccurrenceOfString(".png", with: "@3x.png"))
            )
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

    /// Replaces the last occurrence of the matched substring in a string with another string.
    func replacingLastOccurrenceOfString(_ searchString: String,
                                         with replacementString: String,
                                         caseInsensitive: Bool = true) -> String
    {
        let options: String.CompareOptions
        if caseInsensitive {
            options = [.backwards, .caseInsensitive]
        } else {
            options = [.backwards]
        }

        if let range = range(of: searchString,
                             options: options,
                             range: nil,
                             locale: nil)
        {
            return replacingCharacters(in: range, with: replacementString)
        }
        return self
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

/// Extension on UITraitCollection to create an image with traits from the receiver.
extension UITraitCollection {
    /// Creates the provided image with traits from the receiver.
    func makeImage(_ makeImage: @autoclosure () -> UIImage) -> UIImage {
        var image: UIImage!
        performAsCurrent {
            image = makeImage()
        }
        return image
    }
}
