//
//  FCPExtensions.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import UIKit

// Image Source (no UIImage creation here)
enum ImageSource {
    case url(URL)
    case file(String)
    case flutterAsset(String)
}

// String → ImageSource
extension String {
    func toImageSource() -> ImageSource {
        if self.starts(with: "http") {
            return .url(URL(string: self)!)
        } else if self.starts(with: "file://") {
            return .file(self.replacingOccurrences(of: "file://", with: ""))
        } else {
            return .flutterAsset(self)
        }
    }
}

func makeSafeUIPlaceholder() -> UIImage {
  if Thread.isMainThread {
    return makeUIPlaceholder()
  } else {
    return DispatchQueue.main.sync {
      makeUIPlaceholder()
    }
  }
}

func makeUIPlaceholder() -> UIImage {
  UIGraphicsBeginImageContextWithOptions(CGSize(width: 100, height: 100), false, 0)
  let img = UIGraphicsGetImageFromCurrentImageContext()!
  UIGraphicsEndImageContext()
  return img
}

// UIImage creation (MAIN THREAD ONLY)
@available(iOS 14.0, *)
func makeUIImage(from source: ImageSource) -> UIImage {
    switch source {
    case .url(let url):
        let data = try? Data(contentsOf: url) // Synchronous URL loading (kept for compatibility but avoid using on main thread)
        return data.flatMap { UIImage(data: $0) } ?? UIImage(systemName: "questionmark")!

    case .file(let path):
        return UIImage(contentsOfFile: path) ?? UIImage(systemName: "questionmark")!

    case .flutterAsset(let name):
        let key = SwiftFlutterCarplayPlugin.registrar!.lookupKey(forAsset: name)
        return UIImage(imageLiteralResourceName: key)
    }
}

// Asynchronous image loader. Always calls completion on main thread.
@available(iOS 14.0, *)
func loadUIImageAsync(from source: ImageSource, completion: @escaping (UIImage?) -> Void) {
    switch source {
    case .url(let url):
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            var image: UIImage? = nil
            if let data = data {
                image = UIImage(data: data)
            }
            if let image = image {
                DispatchQueue.main.async { completion(image) }
            } else {
                DispatchQueue.main.async { completion(UIImage(systemName: "questionmark")) }
            }
        }
        task.resume()

    case .file(let path):
        DispatchQueue.global(qos: .userInitiated).async {
            let image = UIImage(contentsOfFile: path) ?? UIImage(systemName: "questionmark")
            DispatchQueue.main.async { completion(image) }
        }

    case .flutterAsset(let name):
        DispatchQueue.main.async {
            let key = SwiftFlutterCarplayPlugin.registrar!.lookupKey(forAsset: name)
            let image = UIImage(imageLiteralResourceName: key)
            completion(image)
        }
    }
}

//  UIImage utilities (safe, UI only)
extension UIImage {
    func resizeImageTo(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

// Regex helper
extension String {
    func match(_ regex: String) -> [[String]] {
        let nsString = self as NSString
        return (try? NSRegularExpression(pattern: regex))?
            .matches(in: self, range: NSRange(location: 0, length: nsString.length))
            .map { match in
                (0..<match.numberOfRanges).map {
                    match.range(at: $0).location == NSNotFound
                    ? ""
                    : nsString.substring(with: match.range(at: $0))
                }
            } ?? []
    }
}
