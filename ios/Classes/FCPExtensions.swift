//
//  FCPExtensions.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

extension UIImage {
  convenience init?(withURL url: URL) throws {
    let imageData = try Data(contentsOf: url)
    self.init(data: imageData)
  }
  
    
  @available(iOS 14.0, *)
  func fromCorrectSource(name: String) -> UIImage {
    if (name.starts(with: "http")) {
      return fromUrl(url: name)
    } else if (name.starts(with: "file://")) {
      return fromFile(path: name)
    }
    return fromFlutterAsset(name: name)
  }
    
  @available(iOS 14.0, *)
  func fromFlutterAsset(name: String) -> UIImage {
    let key: String? = SwiftFlutterCarplayPlugin.registrar?.lookupKey(forAsset: name)
    let image: UIImage? = UIImage(imageLiteralResourceName: key!)
    return image ?? UIImage(systemName: "questionmark")!
  }

  @available(iOS 14.0, *)
  func fromFile(path: String) -> UIImage {
    let cleanPath = path.replacingOccurrences(of: "file://", with: "")
    let image: UIImage? = UIImage(contentsOfFile: cleanPath)
    return image ?? UIImage(systemName: "questionmark")!
  }

  @available(iOS 14.0, *)
  func fromUrl(url: String) -> UIImage {
      let url = URL(string: url)
      let data = try? Data(contentsOf: url!)
      guard let data = data else {
          return UIImage(systemName: "questionmark")!
      }
      return UIImage(data: data)!
  }

  func resizeImageTo(size: CGSize) -> UIImage? {
      UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
      self.draw(in: CGRect(origin: CGPoint.zero, size: size))
      let newImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
      return newImage
    }
}

extension String {
  func match(_ regex: String) -> [[String]] {
    let nsString = self as NSString
    return (try? NSRegularExpression(pattern: regex, options: []))?.matches(in: self, options: [], range: NSMakeRange(0, nsString.length)).map { match in
        (0..<match.numberOfRanges).map { match.range(at: $0).location == NSNotFound ? "" : nsString.substring(with: match.range(at: $0)) }
    } ?? []
  }
}
