//
//  FCPGridButton.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import Flutter

@available(iOS 14.0, *)
class FCPGridButton {
  private(set) var _super: CPGridButton?
  private(set) var elementId: String
  private var titleVariants: [String]
  private var image: String
  private var imageData: FlutterStandardTypedData?
  private var imageTint: FCPImageTint?
  private var isOnPressListenerActive: Bool
  // MARK: - Loading rotation (tap feedback until the event is handled)
  private static let rotationFrameCount = 30
  private var loadingImage: String?
  private var loadingImageData: FlutterStandardTypedData?
  private var loadingImageTint: FCPImageTint?
  private var loadingUIImage: UIImage?
  private var originalImage: UIImage?
  private var rotationFrames: [UIImage] = []
  private var rotationFramesSource: UIImage?
  private var rotationDisplayLink: CADisplayLink?
  private var rotationStep: Int = 0

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.titleVariants = obj["titleVariants"] as! [String]
    self.image = obj["image"] as! String
    self.imageData = obj["imageData"] as? FlutterStandardTypedData
    self.imageTint = FCPImageTint(from: obj["imageTint"] as? [String: Any])
    self.isOnPressListenerActive = obj["onPress"] as? Bool ?? false
    self.loadingImage = obj["loadingImage"] as? String
    self.loadingImageData = obj["loadingImageData"] as? FlutterStandardTypedData
    self.loadingImageTint = FCPImageTint(from: obj["loadingImageTint"] as? [String: Any])
  }

  var get: CPGridButton {
    var gridButton: CPGridButton!
    let image: UIImage
    let imageSource = self.image.toImageSource()
    let bytesImage = makeUIImage(fromBytes: imageData)
    let usesAsyncImage: Bool
    if #available(iOS 26.0, *), bytesImage == nil {
      usesAsyncImage = true
    } else {
      usesAsyncImage = false
    }

    if let bytesImage = bytesImage {
      image = bytesImage.applyingImageTint(imageTint)
    } else if #available(iOS 26.0, *) {
      image = makeSafeUIPlaceholder()
    } else {
      image = makeUIImage(from: imageSource).applyingImageTint(imageTint)
    }

    gridButton = CPGridButton(
      titleVariants: self.titleVariants,
      image: image,
      handler: { _ in
        if self.isOnPressListenerActive {
          DispatchQueue.main.async {
            // Show loading feedback immediately: swap in the loading image
            // (if provided) and rotate it clockwise until Dart calls
            // `onGridButtonPressedComplete`, which triggers
            // `stopLoadingRotation()` and restores the original image.
            self.stopLoadingRotation()
            self.startLoadingRotation()
            FCPStreamHandlerPlugin.sendEvent(
              type: FCPChannelTypes.onGridButtonPressed,
              data: ["elementId": self.elementId]
            )
          }
        }
      }
    )

    if usesAsyncImage {
      loadUIImage(from: self.image, bytes: nil, tint: imageTint) { uiImage in
        gridButton.perform(Selector("updateImage:"), with: uiImage)
      }
    }

    // Preload the optional loading image so it is ready the instant the
    // button is tapped (no async gap before the rotation starts).
    if let loadingImage = self.loadingImage {
      loadUIImage(from: loadingImage, bytes: self.loadingImageData, tint: self.loadingImageTint)
      { [weak self] uiImage in
        self?.loadingUIImage = uiImage
      }
    }

    gridButton.isEnabled = true
    self._super = gridButton
    return gridButton
  }

  /// Applies an in-place content update to the live `CPGridButton`.
  ///
  /// Expects the Dart-side payload produced by `CPGridButton.toJson()`, i.e.
  /// `titleVariants`, `image`, `imageTint` and (for rasterized SVG assets)
  /// `imageData`.
  ///
  /// - Note: `CPGridButton.image` and `CPGridButton.titleVariants` are
  ///   read-only after construction. The only way to change them in place is
  ///   through `updateImage(_:)` / `updateTitleVariants(_:)`, which are
  ///   **iOS 26.0+ only**. On earlier systems the selector does not exist, so
  ///   the update is skipped and a warning is logged instead of crashing.
  ///   Callers that must support iOS 14–18 need the rebuild-based fallback
  ///   (recreate the grid template and re-set it as the root template).
  ///
  /// - Returns: `true` when this button supports in-place updates (iOS 26+),
  ///   `false` when the update was skipped. The return value is resolved
  ///   synchronously from selector availability, so it is safe to use as an
  ///   "is the change visible?" signal even though the image itself may load
  ///   asynchronously afterwards.
  @discardableResult
  public func update(args: [String: Any]) -> Bool {
    guard let gridButton = self._super, /*gridButton*/self.supportsInPlaceUpdate else {
      NSLog(
        "FCP: CPGridButton in-place updates are iOS 26.0+ only. Skipped update for "
          + "elementId \(self.elementId). Rebuild the grid template instead."
      )
      return false
    }

    if let titleVariants = args["titleVariants"] as? [String],
      !titleVariants.isEmpty
    {
      self.titleVariants = titleVariants
      self.applyTitleVariantsUpdate(titleVariants)
    }

    // `image` is always present in the payload, so a tint-only change is
    // re-rendered from the unchanged image path.
    guard let image = args["image"] as? String else { return true }
    let imageData = args["imageData"] as? FlutterStandardTypedData
    let imageTint = FCPImageTint(from: args["imageTint"] as? [String: Any])

    self.image = image
    self.imageTint = imageTint

    loadUIImage(from: image, bytes: imageData, tint: imageTint) { [weak self] uiImage in
      self?.applyImageUpdate(uiImage)
    }

    return true
  }

  /// `CPGridButton.updateImage(_:)` / `updateTitleVariants(_:)` exist from
  /// iOS 26.0 onwards; earlier systems expose neither, so content cannot be
  /// changed in place at all.
  private var supportsInPlaceUpdate: Bool {
    guard let gridButton = self._super else { return false }
    return gridButton.responds(to: NSSelectorFromString("updateImage:"))
      && gridButton.responds(to: NSSelectorFromString("updateTitleVariants:"))
  }

  /// Invokes `CPGridButton.updateImage(_:)` via a dynamic selector.
  ///
  /// The dynamic lookup keeps the package compiling against SDKs that predate
  /// iOS 26, where the symbol does not exist. Callers must have already checked
  /// `supportsInPlaceUpdate`.
  private func applyImageUpdate(_ image: UIImage) {
    guard let gridButton = self._super else { return }
    _ = gridButton.perform(NSSelectorFromString("updateImage:"), with: image)
  }

  /// Invokes `CPGridButton.updateTitleVariants(_:)` via a dynamic selector.
  ///
  /// See `applyImageUpdate(_:)` for why the selector is resolved at runtime.
  private func applyTitleVariantsUpdate(_ titleVariants: [String]) {
    guard let gridButton = self._super else { return }
    _ = gridButton.perform(
      NSSelectorFromString("updateTitleVariants:"), with: titleVariants as NSArray)
  }

  // MARK: - Loading rotation (tap feedback until the event is handled)

  /// Starts an endless clockwise rotation of the button image.
  ///
  /// Called natively the moment the button is tapped, before the
  /// `onGridButtonPressed` event reaches Dart, so the loading state appears
  /// with no perceivable delay. The rotation keeps cycling until
  /// `stopLoadingRotation()` is invoked (via the
  /// `onGridButtonPressedComplete` channel call from Dart) or a new tap
  /// restarts it.
  ///
  /// CarPlay is rendered remotely, so `CPGridButton` (and its image) cannot be
  /// animated with `UIView.animate` or CoreAnimation. The only supported way
  /// to change a live button's image is `updateImage(_:)`, which is available
  /// from iOS 26.0. On earlier systems the animation is skipped and a warning
  /// is logged.
  public func startLoadingRotation() {
    guard !Thread.isMainThread else {
      self.beginLoadingRotation()
      return
    }
    DispatchQueue.main.async { [weak self] in
      self?.beginLoadingRotation()
    }
  }

  private func beginLoadingRotation() {
    guard let gridButton = self._super else { return }
    guard gridButton.responds(to: NSSelectorFromString("updateImage:")) else {
      NSLog(
        "FCP: grid button loading rotation requires iOS 26.0+ "
          + "(CPGridButton.updateImage). Skipped for elementId \(self.elementId)."
      )
      return
    }

    let original = self.originalImage ?? gridButton.image
    self.originalImage = original

    // Use the dedicated loading image when one was provided, otherwise spin
    // the button's own image.
    let source = self.loadingUIImage ?? original

    // Pre-render the rotation frames once per source image and cache them;
    // each `updateImage` call triggers a remote frame on the CarPlay display,
    // so 24 frames (~24 fps) balances smoothness against channel latency.
    if self.rotationFrames.isEmpty || self.rotationFramesSource !== source {
      self.rotationFramesSource = source
      self.rotationFrames = (0..<Self.rotationFrameCount).map { step in
        return source.fcpRotated(by: .pi * 2 * CGFloat(step) / CGFloat(Self.rotationFrameCount))
      }
    }

    self.rotationStep = 0
    self.rotationDisplayLink?.invalidate()
    self.applyImageUpdate(self.rotationFrames[0])
    let link = CADisplayLink(target: self, selector: #selector(rotationTick(_:)))
    link.preferredFramesPerSecond = 30
    self.rotationDisplayLink = link
    link.add(to: .main, forMode: .common)
  }

  /// Stops the loading rotation and restores the original (non-loading) image.
  ///
  /// Safe to call even when no rotation is running.
  public func stopLoadingRotation() {
    guard !Thread.isMainThread else {
      self.endLoadingRotation()
      return
    }
    DispatchQueue.main.async { [weak self] in
      self?.endLoadingRotation()
    }
  }

  private func endLoadingRotation() {
    self.rotationDisplayLink?.invalidate()
    self.rotationDisplayLink?.remove(from: .main, forMode: .common)
    self.rotationDisplayLink = nil
    if let original = self.originalImage {
      self.applyImageUpdate(original)
    }
  }

  @objc private func rotationTick(_ link: CADisplayLink) {
    guard !self.rotationFrames.isEmpty else {
      link.invalidate()
      self.rotationDisplayLink = nil
      return
    }
    // Endless clockwise cycling; the index wraps around naturally via modulo.
    self.rotationStep = (self.rotationStep + 1) % self.rotationFrames.count
    self.applyImageUpdate(self.rotationFrames[self.rotationStep])
  }
}

private extension UIImage {
  /// Returns a copy of the image rotated by `angle` radians around its center.
  ///
  /// The output keeps the original pixel dimensions, so corners may be clipped
  /// for non-square images — grid button icons are square templates, which is
  /// exactly the intended use case here.
  
  /*func fcpRotated(by angle: CGFloat) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale*2
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let rect = CGRect(origin: .zero, size: size)
    return renderer.image { context in
      let cg = context.cgContext
      cg.translateBy(x: size.width / 2, y: size.height / 2)
      cg.rotate(by: angle)
      self.draw(in: rect.offsetBy(dx: -size.width / 2, dy: -size.height / 2))
    }
  }*/
  func fcpRotated(by angle: CGFloat) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale * 2
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let rect = CGRect(origin: .zero, size: size)
    
    let rotatedImage = renderer.image { context in
        let cg = context.cgContext
        cg.translateBy(x: size.width / 2, y: size.height / 2)
        cg.rotate(by: angle)
        self.draw(in: rect.offsetBy(dx: -size.width / 2, dy: -size.height / 2))
    }
    
    // 关键：保留模板渲染模式，让系统自动适配暗黑/浅色
    return rotatedImage.withRenderingMode(.alwaysTemplate)
  }
}
