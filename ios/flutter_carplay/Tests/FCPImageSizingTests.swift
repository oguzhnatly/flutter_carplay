import CarPlay
import Flutter
import UIKit
import XCTest

final class FCPImageSizingTests: XCTestCase {
  override func setUp() {
    super.setUp()
    fcpClearPreparedImageCache()
  }

  private func artwork(_ color: UIColor = .red, size: CGSize = CGSize(width: 80, height: 40)) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      color.setFill()
      UIRectFill(CGRect(origin: .zero, size: size))
    }
  }

  private func pixel(_ image: UIImage, x: Int, y: Int) -> [UInt8] {
    guard let cg = image.cgImage else {
      XCTFail("Missing bitmap: size=\(image.size) scale=\(image.scale) asset=\(String(describing: image.imageAsset))")
      return [0, 0, 0, 0]
    }
    var bytes = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
    let context = CGContext(data: &bytes, width: cg.width, height: cg.height,
                            bitsPerComponent: 8, bytesPerRow: cg.width * 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
    let offset = (y * cg.width + x) * 4
    return Array(bytes[offset..<(offset + 4)])
  }

  func testGridSlotUsesRuntimeMaximum() {
    if #available(iOS 26.0, *) {
      XCTAssertEqual(FCPImageSlot.gridButton(FCPImageSize(from: nil)).maxPt,
                     CPGridTemplate.maximumGridButtonImageSize)
    }
  }

  func testPOISlotUsesPinMaximum() {
    if #available(iOS 16.0, *) {
      XCTAssertEqual(FCPImageSlot.poiPin(FCPImageSize(from: nil)).maxPt,
                     CPPointOfInterest.pinImageSize)
    }
  }

  func testUntintedArtworkPreservesColorAspectAndPadding() {
    let slot = FCPImageSlot.element(CGSize(width: 60, height: 60), FCPImageSize(fraction: 0.5))
    let result = artwork().preparedForCarPlay(slot: slot, tint: nil)
    XCTAssertEqual(result.size, slot.maxPt)
    XCTAssertEqual(result.scale, 2)
    XCTAssertEqual(result.cgImage?.width, 120)
    XCTAssertEqual(result.renderingMode, .alwaysOriginal)
    XCTAssertGreaterThan(pixel(result, x: 60, y: 60)[0], 240)
    XCTAssertLessThan(pixel(result, x: 60, y: 60)[1], 10)
    XCTAssertEqual(pixel(result, x: 10, y: 60)[3], 0)
    XCTAssertEqual(pixel(result, x: 60, y: 10)[3], 0)
  }

  func testColdArtworkCanResolveAtThreeTimesScale() {
    let result = artwork().preparedForCarPlay(
      slot: .element(CGSize(width: 60, height: 60), FCPImageSize(fraction: 1)), tint: nil)
    let traits = UITraitCollection(traitsFrom: [
      UITraitCollection(displayScale: 3), UITraitCollection(userInterfaceStyle: .light)])
    let resolved = result.imageAsset!.image(with: traits)
    XCTAssertEqual(resolved.scale, 3)
    XCTAssertEqual(resolved.cgImage?.width, 180)
  }

  func testUntintedAssetRetainsItsDarkArtwork() {
    let asset = UIImageAsset()
    asset.register(artwork(.red), with: FCPCarTraits.traits(style: .light))
    asset.register(artwork(.blue), with: FCPCarTraits.traits(style: .dark))
    let source = asset.image(with: FCPCarTraits.traits(style: .light))
    let result = source.preparedForCarPlay(
      slot: .element(CGSize(width: 60, height: 60), FCPImageSize(fraction: 1)), tint: nil)
    let dark = result.imageAsset!.image(with: FCPCarTraits.traits(style: .dark))
    XCTAssertGreaterThan(pixel(dark, x: 60, y: 60)[2], 240)
    XCTAssertLessThan(pixel(dark, x: 60, y: 60)[0], 10)
  }

  func testNonfiniteFractionFallsBackToDefault() {
    XCTAssertEqual(FCPImageSize(fraction: .nan).fraction, FCPImageSize.defaultFraction)
    XCTAssertEqual(FCPImageSize(fraction: .infinity).fraction, FCPImageSize.defaultFraction)
    XCTAssertEqual(FCPImageSize(fraction: -.infinity).fraction, FCPImageSize.defaultFraction)
    XCTAssertEqual(FCPImageSize(fraction: -1).fraction, 0.05)
    XCTAssertEqual(FCPImageSize(fraction: 2).fraction, 1)
  }

  func testRotatedArtworkKeepsItsOrientedAspectRatio() {
    let source = UIImage(cgImage: artwork().cgImage!, scale: 1, orientation: .right)
    let result = source.preparedForCarPlay(
      slot: .element(CGSize(width: 60, height: 60), FCPImageSize(fraction: 1)), tint: nil)
    XCTAssertGreaterThan(pixel(result, x: 60, y: 10)[3], 240)
    XCTAssertEqual(pixel(result, x: 10, y: 60)[3], 0)
  }

  func testBytesAndCacheCompletionsAreOnMainThread() {
    let bytes = FlutterStandardTypedData(bytes: artwork().pngData()!)
    let slot = FCPImageSlot.element(CGSize(width: 60, height: 60), FCPImageSize(fraction: 1))
    let done = expectation(description: "bytes and cache callbacks")
    done.expectedFulfillmentCount = 2
    DispatchQueue.global().async {
      loadUIImage(from: "icon.svg", bytes: bytes, slot: slot) { _ in
        XCTAssertTrue(Thread.isMainThread)
        done.fulfill()
        DispatchQueue.global().async {
          loadUIImage(from: "icon.svg", bytes: bytes, slot: slot) { _ in
            XCTAssertTrue(Thread.isMainThread)
            done.fulfill()
          }
        }
      }
    }
    wait(for: [done], timeout: 5)
  }

  func testFailedFileLoadDoesNotPoisonPreparedCache() throws {
    let path = NSTemporaryDirectory() + UUID().uuidString + ".png"
    defer { try? FileManager.default.removeItem(atPath: path) }
    let slot = FCPImageSlot.element(CGSize(width: 60, height: 60), FCPImageSize(fraction: 1))
    let first = expectation(description: "missing file")
    loadUIImage(from: "file://" + path, bytes: nil, slot: slot) { _ in first.fulfill() }
    wait(for: [first], timeout: 5)
    try artwork().pngData()!.write(to: URL(fileURLWithPath: path))
    let second = expectation(description: "retry")
    loadUIImage(from: "file://" + path, bytes: nil, slot: slot) { result in
      XCTAssertGreaterThan(self.pixel(result, x: 60, y: 60)[3], 240)
      second.fulfill()
    }
    wait(for: [second], timeout: 5)
  }

  func testNativeListSizeUpdatesReachBothImages() {
    let bytes = FlutterStandardTypedData(bytes: artwork(size: CGSize(width: 80, height: 80)).pngData()!)
    let model = FCPListItem(obj: ["_elementId": "list", "image": "icon.svg", "imageData": bytes,
      "imageSize": ["fraction": 1.0], "trailingImage": "check.svg", "trailingImageData": bytes,
      "trailingImageSize": ["fraction": 1.0]])
    let native = model.get as! CPListItem
    let oldPrimary = native.image!
    let oldTrailing = native.accessoryImage!
    model.update(args: ["image": "icon.svg", "imageData": bytes, "imageSize": ["fraction": 0.5],
      "trailingImage": "check.svg", "trailingImageData": bytes, "trailingImageSize": ["fraction": 0.5]])
    XCTAssertFalse(native.image === oldPrimary)
    XCTAssertFalse(native.accessoryImage === oldTrailing)
    let image = native.image!
    let width = image.cgImage!.width
    let height = image.cgImage!.height
    XCTAssertEqual(pixel(image, x: 0, y: height / 2)[3], 0)
    XCTAssertGreaterThan(pixel(image, x: width / 2, y: height / 2)[3], 240)
  }

  func testPreparedCacheSeparatesSizesTintsAndSourceBytesAndClears() {
    let bytes = FlutterStandardTypedData(bytes: artwork().pngData()!)
    let changed = FlutterStandardTypedData(bytes: artwork(.blue).pngData()!)
    let small = FCPImageSlot.listItem(FCPImageSize(fraction: 0.5))
    let large = FCPImageSlot.listItem(FCPImageSize(fraction: 1))
    let key = fcpPreparedImageCacheKey(imagePath: "a", imageData: bytes, slot: small, tint: nil)
    XCTAssertNotEqual(key, fcpPreparedImageCacheKey(imagePath: "a", imageData: bytes, slot: large, tint: nil))
    XCTAssertNotEqual(key, fcpPreparedImageCacheKey(imagePath: "a", imageData: changed, slot: small, tint: nil))
    XCTAssertNotEqual(key, fcpPreparedImageCacheKey(imagePath: "a", imageData: bytes, slot: small,
                                                 tint: FCPImageTint(from: ["type": "platform"])))
    loadUIImage(from: "a", bytes: bytes, slot: small) { _ in }
    XCTAssertNotNil(fcpPreparedImageCache.object(forKey: key as NSString))
    fcpClearPreparedImageCache()
    XCTAssertNil(fcpPreparedImageCache.object(forKey: key as NSString))
  }

  func testTintAssetResolvesLightAndDark() {
    let tint = FCPImageTint(from: ["type": "custom", "selectedSafe": false,
      "color": ["red": 255, "green": 0, "blue": 0, "alpha": 1.0],
      "darkColor": ["red": 0, "green": 0, "blue": 255, "alpha": 1.0]])!
    let result = artwork().preparedForCarPlay(
      slot: .element(CGSize(width: 60, height: 60), FCPImageSize(fraction: 1)), tint: tint)
    let light = result.imageAsset!.image(with: FCPCarTraits.traits(style: .light))
    let dark = result.imageAsset!.image(with: FCPCarTraits.traits(style: .dark))
    XCTAssertGreaterThan(pixel(light, x: 60, y: 60)[0], 240)
    XCTAssertGreaterThan(pixel(dark, x: 60, y: 60)[2], 240)
  }
}
