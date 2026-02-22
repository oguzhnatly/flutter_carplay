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
func makeUIImage(
  from source: ImageSource,
  errorCallback: ((Error) -> Void)? = nil
) -> UIImage {
  do {
    switch source {
    case .url(let url):
      let data = try Data(contentsOf: url)
      if let image = UIImage(data: data) {
        return image
      } else {
        throw NSError(
          domain: "ImageLoadError", code: 0,
          userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
      }

    case .file(let path):
      if let image = UIImage(contentsOfFile: path) {
        return image
      } else {
        throw NSError(
          domain: "ImageLoadError", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "File not found or invalid"])
      }

    case .flutterAsset(let name):
      guard !name.isEmpty else {
        throw NSError(
          domain: "ImageLoadError", code: 2,
          userInfo: [NSLocalizedDescriptionKey: "Asset name cannot be empty"])
      }
      let key = SwiftFlutterCarplayPlugin.registrar!.lookupKey(forAsset: name)
      if Bundle.main.path(forResource: key, ofType: nil) != nil {
        throw NSError(
          domain: "ImageLoadError", code: 3,
          userInfo: [NSLocalizedDescriptionKey: "Asset not found in bundle"])
      }
      return UIImage(imageLiteralResourceName: key)
    }
  } catch {
    errorCallback?(error)
    return makeUIPlaceholder()
  }
}

// Asynchronous image loader. Always calls completion on main thread.
@available(iOS 14.0, *)
func loadUIImageAsync(
  from source: ImageSource,
  completion: @escaping (UIImage?) -> Void,
  errorCallback: ((Error) -> Void)? = nil
) {
  switch source {
  case .url(let url):
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
      do {
        if let error = error { throw error }
        guard let data = data, let image = UIImage(data: data) else {
          throw NSError(
            domain: "ImageLoadError", code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        DispatchQueue.main.async { completion(image) }
      } catch {
        DispatchQueue.main.async {
          errorCallback?(error)
          completion(makeUIPlaceholder())
        }
      }
    }
    task.resume()

  case .file(let path):
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        guard let image = UIImage(contentsOfFile: path) else {
          throw NSError(
            domain: "ImageLoadError", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "File not found or invalid"])
        }
        DispatchQueue.main.async { completion(image) }
      } catch {
        DispatchQueue.main.async {
          errorCallback?(error)
          completion(makeUIPlaceholder())
        }
      }
    }

  case .flutterAsset(let name):
    DispatchQueue.main.async {
      do {
        guard !name.isEmpty else {
          throw NSError(
            domain: "ImageLoadError", code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Asset name cannot be empty"])
        }
        let key = SwiftFlutterCarplayPlugin.registrar!.lookupKey(forAsset: name)
        if Bundle.main.path(forResource: key, ofType: nil) != nil {
          throw NSError(
            domain: "ImageLoadError", code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Asset not found in bundle"])
        }
        let image = UIImage(imageLiteralResourceName: key)
        completion(image)
      } catch {
        errorCallback?(error)
        completion(makeUIPlaceholder())
      }
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
