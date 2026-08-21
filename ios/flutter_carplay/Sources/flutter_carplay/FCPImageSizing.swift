//
//  FCPImageSizing.swift
//  flutter_carplay
//
//  Sizing of CarPlay artwork.
//
//  CarPlay does not render in the iPhone's trait environment — it renders in the
//  car's. Apple's headers are explicit about this; from CPListItem.h:
//
//      The *expected* image size for your CPListItem. To properly size your list
//      images, your app should size them to the display scale of the car screen.
//      See -[CPInterfaceController carTraitCollection].
//
//  and identically on CPGridButton. So a display-ready CarPlay image is a bitmap
//  whose pixel dimensions are `maximumImageSize * carDisplayScale`, tagged with
//  `scale == carDisplayScale`, resolved through a UIImageAsset registered against
//  the car's trait collection.
//
//  Re-tagging UIImage.scale without touching the bitmap — what this plugin used
//  to do — does not achieve that: the tag is not what CarPlay resolves against,
//  which is why changing the old `fcpIconTargetPt` constant had no visible
//  effect.
//

import CarPlay
import Flutter
import UIKit

// MARK: - Car trait collection

@available(iOS 14.0, *)
enum FCPCarTraits {
  /// The connected car's trait collection, or nil while CarPlay is disconnected.
  static var current: UITraitCollection? {
    FlutterCarPlaySceneDelegate.carTraitCollection
  }

  /// The car screen's display scale. Real head units report 2.0 or 3.0.
  ///
  /// The fallback is only ever used before `didConnect` has fired; 2.0 is chosen
  /// over `UIScreen.main.scale` deliberately, because the phone's scale has no
  /// relationship to the car's and guessing 3.0 would render everything oversized
  /// on a 2x head unit.
  static var displayScale: CGFloat {
    let scale = current?.displayScale ?? 0
    return scale > 0 ? scale : 2.0
  }

  /// `base` merged with an explicit user interface style, so that images
  /// registered into a `UIImageAsset` carry both the car's display scale and the
  /// light/dark variant.
  static func traits(style: UIUserInterfaceStyle) -> UITraitCollection {
    let styleTraits = UITraitCollection(userInterfaceStyle: style)
    if let carTraits = current {
      return UITraitCollection(traitsFrom: [carTraits, styleTraits])
    }
    return UITraitCollection(traitsFrom: [
      UITraitCollection(displayScale: displayScale), styleTraits,
    ])
  }
}

// MARK: - Requested size

/// The size a single image was asked to render at, as a fraction of the slot
/// that CarPlay reserves for it.
///
/// Fractions rather than absolute points: the reserved slot differs per car and
/// per app category, so a fraction is the only value that stays correct across
/// head units and can never overflow the slot.
///
/// The Dart side resolves per-image override -> global `FlutterCarplay.iconSize`
/// -> default before sending, so `imageSize` is normally present in the payload.
/// The default here only covers payloads from older callers.
struct FCPImageSize {
  static let defaultFraction: CGFloat = 0.7

  let fraction: CGFloat

  init(fraction: CGFloat) {
    self.fraction = min(max(fraction, 0.05), 1.0)
  }

  init(from dict: [String: Any]?) {
    guard let dict = dict, let fraction = dict["fraction"] as? NSNumber else {
      self.init(fraction: FCPImageSize.defaultFraction)
      return
    }
    self.init(fraction: CGFloat(fraction.doubleValue))
  }

  var cacheKey: String { String(format: "%.4f", fraction) }
}

// MARK: - Slots

/// A CarPlay artwork slot: the point size CarPlay expects, plus how much of it
/// the artwork should occupy.
@available(iOS 14.0, *)
struct FCPImageSlot {
  let maxPt: CGSize
  let size: FCPImageSize

  var fraction: CGFloat { size.fraction }

  /// CPGridButton is the one image-bearing class with no `maximumImageSize` in
  /// the SDK; its header only points at `carTraitCollection`. 88x88pt is Apple's
  /// documented grid artwork size.
  static let gridButtonMaxPt = CGSize(width: 88, height: 88)

  static func listItem(_ size: FCPImageSize) -> FCPImageSlot {
    FCPImageSlot(maxPt: CPListItem.maximumImageSize, size: size)
  }

  static func gridButton(_ size: FCPImageSize) -> FCPImageSlot {
    FCPImageSlot(maxPt: gridButtonMaxPt, size: size)
  }

  /// POI pin images are sized against `CPButtonMaximumImageSize`, the SDK
  /// constant for button artwork, rather than a hardcoded value.
  ///
  /// Referenced as the bare global rather than `CPButton.maximumImageSize`:
  /// CarPlay.apinotes declares that rename under `Tags:` instead of `Globals:`,
  /// so the mapping never applies and the member form does not exist in Swift.
  static func poiPin(_ size: FCPImageSize) -> FCPImageSlot {
    FCPImageSlot(maxPt: CPButtonMaximumImageSize, size: size)
  }

  /// Legacy `CPListImageRowItem.gridImages`. `CPListImageRowItem.maximumImageSize`
  /// is deprecated from iOS 26 in favour of the per-element property, so prefer
  /// the grid element's value where it exists.
  static func legacyGridImage(_ size: FCPImageSize) -> FCPImageSlot {
    if #available(iOS 26.0, *) {
      return FCPImageSlot(maxPt: CPListImageRowItemGridElement.maximumImageSize, size: size)
    }
    return FCPImageSlot(maxPt: CPListImageRowItem.maximumImageSize, size: size)
  }

  static func element(_ maxPt: CGSize, _ size: FCPImageSize) -> FCPImageSlot {
    FCPImageSlot(maxPt: maxPt, size: size)
  }

  var cacheKey: String {
    "\(Int(maxPt.width))x\(Int(maxPt.height))|\(size.cacheKey)|\(FCPCarTraits.displayScale)"
  }
}

// MARK: - Rendering

/// Images already prepared for CarPlay, keyed by source + slot + tint.
///
/// Unlike the previous cache this also holds untinted images, because every
/// image is now resampled and that work is worth caching regardless of tint.
let fcpPreparedImageCache = NSCache<NSString, UIImage>()

@available(iOS 14.0, *)
func fcpClearPreparedImageCache() {
  fcpPreparedImageCache.removeAllObjects()
}

@available(iOS 14.0, *)
func fcpPreparedImageCacheKey(
  imagePath: String,
  imageData: FlutterStandardTypedData?,
  slot: FCPImageSlot,
  tint: FCPImageTint?
) -> String {
  let bytesKey = imageData.map { "bytes:\($0.data.count):\($0.data.hashValue)" } ?? "nil"
  return [imagePath, bytesKey, slot.cacheKey, tint?.cacheKey ?? "notint"].joined(separator: "|")
}

@available(iOS 14.0, *)
extension UIImage {
  /// Returns a display-ready CarPlay image for `slot`.
  ///
  /// The artwork is aspect-fit to `slot.fraction` of the slot's edge length and
  /// centred on a transparent canvas of *exactly* `slot.maxPt`, rendered at
  /// `maxPt * carDisplayScale` pixels.
  ///
  /// The padded canvas is the point of the whole exercise. Because the canvas is
  /// always exactly the size CarPlay expects, CarPlay neither scales it up nor
  /// down — whether it draws artwork at its natural size or fits it into the
  /// reserved slot. The visible glyph size therefore depends solely on
  /// `fraction`, which is what makes the size controllable at all. A tightly
  /// cropped image would be at CarPlay's mercy: if it fits-to-slot, the fraction
  /// silently does nothing.
  ///
  /// It also matches how SF Symbols look. Those carry roughly 25-30% internal
  /// padding, whereas the Dart SVG rasterizer fills its square edge to edge —
  /// which is why untouched SVG icons read as oversized next to native ones even
  /// when their point size is correct.
  func preparedForCarPlay(slot: FCPImageSlot, tint: FCPImageTint?) -> UIImage {
    guard Thread.isMainThread else {
      return DispatchQueue.main.sync { self.preparedForCarPlay(slot: slot, tint: tint) }
    }

    let canvas = slot.maxPt
    guard canvas.width > 0, canvas.height > 0 else { return self }

    let base = drawnOnCarPlayCanvas(canvas: canvas, fraction: slot.fraction)

    guard let tint = tint else {
      return base.resolvedAgainstCarTraits(light: base, dark: base)
    }

    let light = base.tintedGlyph(
      with: tint.color(for: .light).resolvedColor(with: FCPCarTraits.traits(style: .light)),
      selectedSafe: tint.selectedSafe
    )
    let dark = base.tintedGlyph(
      with: tint.color(for: .dark).resolvedColor(with: FCPCarTraits.traits(style: .dark)),
      selectedSafe: tint.selectedSafe
    )
    return base.resolvedAgainstCarTraits(light: light, dark: dark)
  }

  /// Draws the receiver aspect-fit at `fraction` of the canvas, centred, on a
  /// transparent canvas of `canvas` points at the car's display scale.
  private func drawnOnCarPlayCanvas(canvas: CGSize, fraction: CGFloat) -> UIImage {
    let carScale = FCPCarTraits.displayScale

    let format = UIGraphicsImageRendererFormat()
    format.scale = carScale
    format.opaque = false

    // Source dimensions in pixels: `size` is already divided by the decoded
    // image's own scale, which for our inputs is an artifact of how the bitmap
    // was created and says nothing about intended display size.
    let sourceWidth = CGFloat(cgImage?.width ?? Int(size.width * scale))
    let sourceHeight = CGFloat(cgImage?.height ?? Int(size.height * scale))
    guard sourceWidth > 0, sourceHeight > 0 else { return self }

    let targetWidth = canvas.width * fraction
    let targetHeight = canvas.height * fraction
    let fit = min(targetWidth / sourceWidth, targetHeight / sourceHeight)
    let drawSize = CGSize(width: sourceWidth * fit, height: sourceHeight * fit)
    let origin = CGPoint(
      x: (canvas.width - drawSize.width) / 2,
      y: (canvas.height - drawSize.height) / 2
    )

    let renderer = UIGraphicsImageRenderer(size: canvas, format: format)
    return renderer.image { _ in
      draw(in: CGRect(origin: origin, size: drawSize))
    }
  }

  /// Combines light and dark variants into a `UIImageAsset` registered against
  /// the *car's* trait collection.
  ///
  /// This is the step an Apple Frameworks engineer called out as the one that
  /// binds the image to the car screen's scale rather than the phone's
  /// (developer.apple.com/forums/thread/695636). The returned image keeps a
  /// reference to the asset, so CarPlay re-resolves it when the car switches
  /// between day and night mode.
  private func resolvedAgainstCarTraits(light: UIImage, dark: UIImage) -> UIImage {
    let lightTraits = FCPCarTraits.traits(style: .light)
    let darkTraits = FCPCarTraits.traits(style: .dark)

    let asset = UIImageAsset()
    asset.register(light, with: lightTraits)
    asset.register(dark, with: darkTraits)

    let resolveWith = FCPCarTraits.current ?? lightTraits
    return asset.image(with: resolveWith).withRenderingMode(.alwaysOriginal)
  }
}

// MARK: - Tinting

@available(iOS 14.0, *)
extension UIImage {
  /// Flattens the receiver to a solid-colour silhouette using its own alpha as
  /// the mask.
  ///
  /// Destructive by nature, which is why tinting stays opt-in via
  /// `AutoImageTint`: applying it to multicolour artwork (country flags, logos)
  /// would reduce it to a single-colour block.
  fileprivate func tintedGlyph(with color: UIColor, selectedSafe: Bool) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    format.opaque = false

    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let rect = CGRect(origin: .zero, size: size)
    let glyph = renderer.image { _ in
      color.setFill()
      UIRectFill(rect)
      draw(in: rect, blendMode: .destinationIn, alpha: 1)
    }.withRenderingMode(.alwaysOriginal)

    guard selectedSafe else { return glyph }

    return renderer.image { context in
      let shadowColor = contrastColor(for: color).cgColor
      let blur = max(1, min(size.width, size.height) * 0.06)
      context.cgContext.setShadow(offset: .zero, blur: blur, color: shadowColor)
      glyph.draw(in: rect)
      context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
      glyph.draw(in: rect)
    }.withRenderingMode(.alwaysOriginal)
  }

  private func contrastColor(for color: UIColor) -> UIColor {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
    if luminance > 0.55 {
      return UIColor.black.withAlphaComponent(0.85)
    }
    return UIColor.white.withAlphaComponent(0.95)
  }
}

// MARK: - Diagnostics

/// Opt-in logging of the values that actually drive CarPlay image sizing.
///
/// Enabled from Dart via `FlutterCarplay.debugImageSizing`. These numbers differ
/// between the Xcode CarPlay simulator and a real head unit — that difference is
/// exactly where the oversized-icon bug lived — so they are worth being able to
/// read off both.
@available(iOS 14.0, *)
enum FCPImageDiagnostics {
  static var isEnabled = false

  static func logEnvironment() {
    guard isEnabled else { return }
    let traits = FCPCarTraits.current
    NSLog(
      """
      [flutter_carplay/sizing] car connected=\(traits != nil) \
      displayScale=\(FCPCarTraits.displayScale) \
      userInterfaceStyle=\(traits?.userInterfaceStyle.rawValue ?? -1) \
      CPListItem.maximumImageSize=\(CPListItem.maximumImageSize) \
      CPButtonMaximumImageSize=\(CPButtonMaximumImageSize) \
      gridButtonMaxPt=\(FCPImageSlot.gridButtonMaxPt)
      """
    )
  }

  static func log(
    _ label: String,
    source: String,
    before: UIImage,
    after: UIImage,
    slot: FCPImageSlot
  ) {
    guard isEnabled else { return }
    NSLog(
      """
      [flutter_carplay/sizing] \(label) source=\(source) \
      slot=\(slot.maxPt) fraction=\(slot.fraction) \
      before: size=\(before.size) scale=\(before.scale) \
      px=\(before.cgImage?.width ?? -1)x\(before.cgImage?.height ?? -1) \
      after: size=\(after.size) scale=\(after.scale) \
      px=\(after.cgImage?.width ?? -1)x\(after.cgImage?.height ?? -1)
      """
    )
  }
}
