import CarPlay
import Flutter

@available(iOS 14.0, *)
class FCPGridButton {
  typealias ImageLoader = (String, FlutterStandardTypedData?, FCPImageTint?, @escaping (UIImage) -> Void) -> Void

  private(set) var _super: CPGridButton?
  private(set) var elementId: String
  private(set) var activePressId: String?
  private let titleVariants: [String]
  private let image: String
  private let imageData: FlutterStandardTypedData?
  private let imageTint: FCPImageTint?
  private let imageSize: FCPImageSize
  private let isOnPressListenerActive: Bool
  private let usesLoading: Bool
  private let imageLoader: ImageLoader
  private let loadingImage: String?
  private let loadingImageData: FlutterStandardTypedData?
  private let loadingImageTint: FCPImageTint?
  private var isVisible = true
  private var loadingUIImage: UIImage?
  private var originalImage: UIImage?
  private static let rotationFrameCount = 30
  private var rotationFrames: [UIImage] = []
  private var rotationFramesSource: UIImage?
  private var rotationDisplayLink: CADisplayLink?
  private var rotationStep = 0

  init(obj: [String: Any], imageLoader: ImageLoader? = nil) {
    elementId = obj["_elementId"] as! String
    titleVariants = obj["titleVariants"] as! [String]
    image = obj["image"] as! String
    imageData = obj["imageData"] as? FlutterStandardTypedData
    imageTint = FCPImageTint(from: obj["imageTint"] as? [String: Any])
    imageSize = FCPImageSize(from: obj["imageSize"] as? [String: Any])
    isOnPressListenerActive = obj["onPress"] as? Bool ?? false
    usesLoading = obj["usesLoading"] as? Bool ?? false
    loadingImage = obj["loadingImage"] as? String
    loadingImageData = obj["loadingImageData"] as? FlutterStandardTypedData
    loadingImageTint = FCPImageTint(from: obj["loadingImageTint"] as? [String: Any])
    let slot = FCPImageSlot.gridButton(imageSize)
    self.imageLoader = imageLoader ?? { path, bytes, tint, completion in
      loadUIImage(from: path, bytes: bytes, slot: slot, tint: tint, completion: completion)
    }
  }

  var get: CPGridButton {
    if let button = _super { return button }
    let bytesImage = makeUIImage(fromBytes: imageData)
    let initial: UIImage
    if let bytesImage = bytesImage {
      initial = bytesImage.preparedForCarPlay(slot: .gridButton(imageSize), tint: imageTint)
    } else if #available(iOS 26.0, *) {
      initial = makeSafeUIPlaceholder(slot: .gridButton(imageSize))
    } else {
      initial = makeUIImage(from: image.toImageSource()).preparedForCarPlay(slot: .gridButton(imageSize), tint: imageTint)
    }
    originalImage = initial
    let button = CPGridButton(titleVariants: titleVariants, image: initial) { [weak self] _ in
      self?.onMain { $0.handlePress() }
    }
    _super = button
    button.isEnabled = true

    if #available(iOS 26.0, *), bytesImage == nil {
      imageLoader(image, nil, imageTint) { [weak self] image in
        self?.onMain { owner in
          owner.originalImage = image
          if owner.rotationDisplayLink != nil {
            // The normal image can arrive after the tap too. Never restore a placeholder.
            owner.beginLoadingRotation()
          } else {
            owner.applyImageUpdate(image)
          }
        }
      }
    }
    if usesLoading, #available(iOS 26.0, *), let path = loadingImage {
      imageLoader(path, loadingImageData, loadingImageTint) { [weak self] image in
        self?.onMain { owner in
          owner.loadingUIImage = image
          if owner.rotationDisplayLink != nil { owner.beginLoadingRotation() }
        }
      }
    }
    return button
  }

  // Invoked by the native tap closure, on the main thread.
  func handlePress() {
    guard isVisible, isOnPressListenerActive, activePressId == nil else { return }
    var data = ["elementId": elementId]
    if usesLoading {
      let pressId = UUID().uuidString
      activePressId = pressId
      data["pressId"] = pressId
      _super?.isEnabled = false
      beginLoadingRotation()
    }
    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onGridButtonPressed, data: data)
  }

  @discardableResult
  func completePress(pressId: String) -> Bool {
    guard activePressId == pressId else { return false }
    activePressId = nil
    endLoadingRotation()
    _super?.isEnabled = true
    return true
  }

  func setVisible(_ visible: Bool) {
    onMain { owner in
      if !visible {
        owner.activePressId = nil
        owner.endLoadingRotation()
        owner._super?.isEnabled = true
      }
      owner.isVisible = visible
      if visible, owner.rotationDisplayLink == nil, let image = owner.originalImage {
        owner.applyImageUpdate(image)
      }
    }
  }

  func startLoadingRotation() { onMain { $0.beginLoadingRotation() } }
  func stopLoadingRotation() { onMain { $0.endLoadingRotation() } }

  private func onMain(_ action: @escaping (FCPGridButton) -> Void) {
    if Thread.isMainThread { action(self) }
    else { DispatchQueue.main.async { [weak self] in if let self = self { action(self) } } }
  }

  private func applyImageUpdate(_ image: UIImage) {
    guard isVisible, #available(iOS 26.0, *) else { return }
    _super?.updateImage(image)
  }

  private func beginLoadingRotation() {
    guard isVisible, #available(iOS 26.0, *), let original = originalImage, _super != nil else { return }
    let source = loadingUIImage ?? original
    if rotationFrames.isEmpty || rotationFramesSource !== source {
      rotationFramesSource = source
      rotationFrames = (0..<Self.rotationFrameCount).map { step in
        source.fcpRotated(by: .pi * 2 * CGFloat(step) / CGFloat(Self.rotationFrameCount))
      }
    }
    rotationStep = 0
    rotationDisplayLink?.invalidate()
    applyImageUpdate(rotationFrames[0])
    // The run loop retains its display link; its proxy must not retain the button.
    let link = CADisplayLink(target: GridRotationTarget(self), selector: #selector(GridRotationTarget.tick(_:)))
    link.preferredFramesPerSecond = Self.rotationFrameCount
    rotationDisplayLink = link
    link.add(to: .main, forMode: .common)
  }

  private func endLoadingRotation() {
    let wasRotating = rotationDisplayLink != nil
    rotationDisplayLink?.invalidate()
    rotationDisplayLink = nil
    rotationFrames.removeAll()
    rotationFramesSource = nil
    if wasRotating, let original = originalImage { applyImageUpdate(original) }
  }

  fileprivate func rotationTick(_ link: CADisplayLink) {
    guard isVisible, rotationDisplayLink === link, !rotationFrames.isEmpty else { link.invalidate(); return }
    rotationStep = (rotationStep + 1) % rotationFrames.count
    applyImageUpdate(rotationFrames[rotationStep])
  }

  deinit { rotationDisplayLink?.invalidate() }
}

@available(iOS 14.0, *)
private final class GridRotationTarget: NSObject {
  weak var button: FCPGridButton?
  init(_ button: FCPGridButton) { self.button = button }
  @objc func tick(_ link: CADisplayLink) {
    guard let button = button else { link.invalidate(); return }
    button.rotationTick(link)
  }
}

private extension UIImage {
  func fcpRotated(by angle: CGFloat) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { context in
      let cg = context.cgContext
      cg.translateBy(x: size.width / 2, y: size.height / 2)
      cg.rotate(by: angle)
      draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
    }.withRenderingMode(renderingMode)
  }
}
