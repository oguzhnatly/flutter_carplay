//
//  FCPExtensions.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

extension UIImage {
    convenience init?(withURL url: URL) throws {
        let imageData = try Data(contentsOf: url)
        self.init(data: imageData)
    }

    @available(iOS 14.0, *)
    func fromFlutterAsset(name: String) -> UIImage {
        let key: String? = SwiftFlutterCarplayPlugin.registrar?.lookupKey(forAsset: name)
        let image: UIImage? = UIImage(imageLiteralResourceName: key!)
        return image ?? UIImage(systemName: "questionmark")!
    }

    func resizeImageTo(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension String {
    func match(_ regex: String) -> [[String]] {
        let nsString = self as NSString
        return (try? NSRegularExpression(pattern: regex, options: []))?.matches(in: self, options: [], range: NSMakeRange(0, nsString.length)).map { match in
            (0 ..< match.numberOfRanges).map { match.range(at: $0).location == NSNotFound ? "" : nsString.substring(with: match.range(at: $0)) }
        } ?? []
    }
}

extension CPTemplate {
    func setFCPTemplate(_ template: FCPTemplate) {
        userInfo = ["FCPObject": template]
    }
}

extension CPListItem {
    func setFCPTemplate(_ item: FCPListItem) {
        userInfo = ["FCPObject": item]
    }
}
