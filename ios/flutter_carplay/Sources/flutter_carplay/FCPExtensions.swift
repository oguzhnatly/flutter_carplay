//
//  FCPExtensions.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import Flutter
import UIKit

// Creates a UIImage from raw PNG bytes sent over the MethodChannel.
// Used for Flutter asset SVGs that are rasterized to PNG on the Dart side,
// since UIImage cannot decode SVG directly. Returns nil when the data is
// missing or cannot be decoded so callers can fall back to string resolution.
//
// The bytes are decoded at their natural pixel size. Sizing for CarPlay happens
// later in `preparedForCarPlay(slot:tint:)`, which resamples against the car's
// display scale — see FCPImageSizing.swift. This deliberately no longer re-tags
// UIImage.scale to fake a point size; that trick is what made icons oversized.
func makeUIImage(fromBytes data: FlutterStandardTypedData?) -> UIImage? {
  guard let data = data else { return nil }
  return UIImage(data: data.data)
}

/// Loads an image from `imageData` (rasterized SVG bytes) or `imagePath`, then
/// renders it display-ready for `slot`.
///
/// Results are cached per source + slot + tint, including untinted images, since
/// every image now goes through a resampling pass.
@available(iOS 14.0, *)
func loadUIImage(
  from imagePath: String,
  bytes imageData: FlutterStandardTypedData?,
  slot: FCPImageSlot,
  tint imageTint: FCPImageTint? = nil,
  completion: @escaping (UIImage) -> Void
) {
  let cacheKey = fcpPreparedImageCacheKey(
    imagePath: imagePath, imageData: imageData, slot: slot, tint: imageTint)
  if let cachedImage = fcpPreparedImageCache.object(forKey: cacheKey as NSString) {
    completion(cachedImage)
    return
  }

  func complete(_ image: UIImage) {
    let result = image.preparedForCarPlay(slot: slot, tint: imageTint)
    FCPImageDiagnostics.log(
      "loadUIImage", source: imagePath, before: image, after: result, slot: slot)
    fcpPreparedImageCache.setObject(result, forKey: cacheKey as NSString)
    completion(result)
  }

  if let bytesImage = makeUIImage(fromBytes: imageData) {
    complete(bytesImage)
    return
  }

  loadUIImageAsync(from: imagePath.toImageSource()) { uiImage in
    if let uiImage = uiImage {
      complete(uiImage)
    }
  }
}

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

/// A transparent stand-in shown while the real image loads asynchronously,
/// sized to exactly the slot CarPlay reserves, at the car's display scale.
///
/// The size matters: CarPlay lays the row out from whatever image it is handed
/// first. The previous flat 100x100pt placeholder made rows reserve space for a
/// 100pt icon before the real artwork ever arrived.
@available(iOS 14.0, *)
func makeSafeUIPlaceholder(slot: FCPImageSlot) -> UIImage {
  if Thread.isMainThread {
    return makeUIPlaceholder(size: slot.maxPt)
  }
  return DispatchQueue.main.sync {
    makeUIPlaceholder(size: slot.maxPt)
  }
}

@available(iOS 14.0, *)
func makeSafeUIPlaceholder() -> UIImage {
  makeSafeUIPlaceholder(slot: .listItem(FCPImageSize(fraction: FCPImageSize.defaultFraction)))
}

@available(iOS 14.0, *)
func makeUIPlaceholder(size: CGSize = CPListItem.maximumImageSize) -> UIImage {
  let format = UIGraphicsImageRendererFormat()
  format.scale = FCPCarTraits.displayScale
  format.opaque = false

  let renderer = UIGraphicsImageRenderer(size: size, format: format)
  return renderer.image { _ in
    UIColor.clear.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
  }
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
      guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
        throw NSError(
          domain: "ImageLoadError", code: 3,
          userInfo: [NSLocalizedDescriptionKey: "Asset not found in bundle"])
      }
      guard let image = UIImage(contentsOfFile: path) else {
        throw NSError(
          domain: "ImageLoadError", code: 4,
          userInfo: [NSLocalizedDescriptionKey: "Failed to decode image at path: \(path)"])
      }
      return image
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
        guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
          throw NSError(
            domain: "ImageLoadError", code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Asset not found in bundle"])
        }
        guard let image = UIImage(contentsOfFile: path) else {
          throw NSError(
            domain: "ImageLoadError", code: 4,
            userInfo: [NSLocalizedDescriptionKey: "Failed to decode image at path: \(path)"])
        }
        completion(image)
      } catch {
        errorCallback?(error)
        completion(makeUIPlaceholder())
      }
    }
  }
}

/// Resolve a tab icon from [systemIcon]:
/// 1. Named SF Symbol (ex: "star") → `UIImage(systemName:)`
/// 2. Image source (URL, file, Flutter asset) → loaded via `makeUIImage` /
///    `loadUIImageAsync`, using a placeholder on iOS 26+ while loading async.
///
/// The [applyImage] closure is called once with the resolved image so that
/// the caller can assign it to the appropriate template property.
@available(iOS 14.0, *)
func resolveTabIcon(
  _ systemIcon: String,
  applyImage: @escaping (UIImage?) -> Void
) {
  // 1. SF Symbol — resolved synchronously
  if let sysImage = UIImage(systemName: systemIcon) {
    applyImage(sysImage)
    return
  }

  // 2. Image source (URL, file, asset)
  let imageSource = systemIcon.toImageSource()
  if #available(iOS 26.0, *) {
    applyImage(makeSafeUIPlaceholder())
    loadUIImageAsync(from: imageSource) { uiImage in
      applyImage(uiImage)
    }
  } else {
    applyImage(makeUIImage(from: imageSource))
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
