import CarPlay
import Flutter
import UIKit
import XCTest

// Control the transport, not the wrapper or renderer: these requests use the
// production URLSession loader and complete with real PNG artwork.
private final class OrderedArtworkProtocol: URLProtocol {
  private static let lock = NSLock()
  private static var pending: [String: [OrderedArtworkProtocol]] = [:]

  override class func canInit(with request: URLRequest) -> Bool {
    request.url?.host == "artworkorder.invalid"
  }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    Self.lock.lock()
    Self.pending[request.url!.absoluteString, default: []].append(self)
    Self.lock.unlock()
  }
  override func stopLoading() {}

  static func count(_ source: String) -> Int {
    lock.lock()
    defer { lock.unlock() }
    return pending[source]?.count ?? 0
  }

  static func finish(_ source: String, data: Data, index: Int = 0) {
    lock.lock()
    let instance = pending[source]!.remove(at: index)
    lock.unlock()
    instance.client?.urlProtocol(instance, didReceive: URLResponse(
      url: instance.request.url!, mimeType: "image/png", expectedContentLength: data.count,
      textEncodingName: nil), cacheStoragePolicy: .notAllowed)
    instance.client?.urlProtocol(instance, didLoad: data)
    instance.client?.urlProtocolDidFinishLoading(instance)
  }
}

@available(iOS 26.0, *)
final class ArtworkUpdateOrderTests: XCTestCase {
  private enum Kind: String, CaseIterable {
    case primary, trailing, card, condensed, grid, imageGrid, row

    var maxSize: CGSize {
      switch self {
      case .primary, .trailing: return CPListItem.maximumImageSize
      case .card: return CPListImageRowItemCardElement.maximumImageSize
      case .condensed: return CPListImageRowItemCondensedElement.maximumImageSize
      case .grid: return CPListImageRowItemGridElement.maximumImageSize
      case .imageGrid: return CPListImageRowItemImageGridElement.maximumImageSize
      case .row: return CPListImageRowItemRowElement.maximumImageSize
      }
    }
  }

  private struct Target {
    let owner: AnyObject
    let read: () -> UIImage?
    let update: ([String: Any]) -> Void
  }

  override func setUp() {
    super.setUp()
    XCTAssertTrue(URLProtocol.registerClass(OrderedArtworkProtocol.self))
    fcpClearPreparedImageCache()
  }

  override func tearDown() {
    URLProtocol.unregisterClass(OrderedArtworkProtocol.self)
    super.tearDown()
  }

  private func artwork(_ color: UIColor) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40), format: format).image { _ in
      color.setFill()
      UIRectFill(CGRect(x: 0, y: 0, width: 40, height: 40))
    }
  }

  private func payload(_ source: String, fraction: Double = 1,
                       tint: [String: Any]? = nil) -> [String: Any] {
    var result: [String: Any] = ["_elementId": "artwork", "image": source,
      "imageSize": ["fraction": fraction], "title": "Title", "subtitle": "Subtitle",
      "showsImageFullHeight": false, "accessorySymbolName": "star"]
    if let tint = tint { result["imageTint"] = tint }
    return result
  }

  private func target(_ kind: Kind, _ data: [String: Any]) -> Target {
    switch kind {
    case .primary, .trailing:
      func mapped(_ input: [String: Any]) -> [String: Any] {
        guard kind == .trailing else { return input }
        var result = input
        for suffix in ["", "Data", "Tint", "Size"] {
          if let value = result.removeValue(forKey: "image" + suffix) {
            result["trailingImage" + suffix] = value
          }
        }
        return result
      }
      let model = FCPListItem(obj: mapped(data))
      let native = model.get as! CPListItem
      return Target(owner: model, read: { kind == .primary ? native.image : native.accessoryImage },
                    update: { model.update(args: mapped($0)) })
    case .card:
      let model = FCPListImageRowItemCardElement(obj: data)
      let native = model.get as! CPListImageRowItemCardElement
      return Target(owner: model, read: { native.image }, update: { model.update(args: $0) })
    case .condensed:
      let model = FCPListImageRowItemCondensedElement(obj: data)
      let native = model.get as! CPListImageRowItemCondensedElement
      return Target(owner: model, read: { native.image }, update: { model.update(args: $0) })
    case .grid:
      let model = FCPListImageRowItemGridElement(obj: data)
      let native = model.get as! CPListImageRowItemGridElement
      return Target(owner: model, read: { native.image }, update: { model.update(args: $0) })
    case .imageGrid:
      let model = FCPListImageRowItemImageGridElement(obj: data)
      let native = model.get as! CPListImageRowItemImageGridElement
      return Target(owner: model, read: { native.image }, update: { model.update(args: $0) })
    case .row:
      let model = FCPListImageRowItemRowElement(obj: data)
      let native = model.get as! CPListImageRowItemRowElement
      return Target(owner: model, read: { native.image }, update: { model.update(args: $0) })
    }
  }

  private func awaitCondition(_ description: String, _ condition: @escaping () -> Bool) {
    let done = expectation(description: description)
    let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
      if condition() { timer.invalidate(); done.fulfill() }
    }
    defer { timer.invalidate() }
    wait(for: [done], timeout: 5)
  }

  private func awaitRequest(_ source: String, count: Int = 1) {
    awaitCondition("request started") { OrderedArtworkProtocol.count(source) == count }
  }

  private func finish(_ source: String, kind: Kind, fraction: Double,
                      color: UIColor = .red, tint: [String: Any]? = nil, index: Int = 0) {
    let key = fcpPreparedImageCacheKey(imagePath: source, imageData: nil,
      slot: .element(kind.maxSize, FCPImageSize(fraction: CGFloat(fraction))),
      tint: FCPImageTint(from: tint))
    let pending = fcpPreparedImageLoads[key]?.count ?? 0
    XCTAssertGreaterThan(pending, 0)
    OrderedArtworkProtocol.finish(source, data: artwork(color).pngData()!, index: index)
    awaitCondition("production renderer and completion finished") {
      (fcpPreparedImageLoads[key]?.count ?? 0) == pending - 1
    }
  }

  private func assertSizeOrdering(_ kind: Kind) {
    let source = "https://artworkorder.invalid/\(UUID().uuidString).png"
    let model = target(kind, payload(source))
    awaitRequest(source)
    model.update(payload(source, fraction: 0.5))
    awaitRequest(source, count: 2)
    model.update(payload(source, fraction: 0.25))
    awaitRequest(source, count: 3)
    // Finish initial get first, then the newest update, then the stale update.
    let placeholder = model.read()!.pngData()
    // CarPlay normalizes UIImage.scale in its getter; verify the bitmap slot.
    XCTAssertEqual(model.read()!.cgImage!.width, Int(kind.maxSize.width * FCPCarTraits.displayScale))
    finish(source, kind: kind, fraction: 1)
    XCTAssertEqual(model.read()!.pngData(), placeholder, "Initial get must not override newer placeholder")
    finish(source, kind: kind, fraction: 0.25, index: 1)
    let newest = model.read()!.pngData()
    finish(source, kind: kind, fraction: 0.5)
    XCTAssertEqual(model.read()!.pngData(), newest, "\(kind): stale size replaced newest artwork")
  }

  func testPrimaryRejectsStaleSizeUpdate() { assertSizeOrdering(.primary) }
  func testTrailingRejectsStaleSizeUpdate() { assertSizeOrdering(.trailing) }
  func testCardRejectsStaleSizeUpdate() { assertSizeOrdering(.card) }
  func testCondensedRejectsStaleSizeUpdate() { assertSizeOrdering(.condensed) }
  func testGridRejectsStaleSizeUpdate() { assertSizeOrdering(.grid) }
  func testImageGridRejectsStaleSizeUpdate() { assertSizeOrdering(.imageGrid) }
  func testRowRejectsStaleSizeUpdate() { assertSizeOrdering(.row) }

  private func customTint(red: Int, green: Int, blue: Int) -> [String: Any] {
    ["type": "custom", "selectedSafe": false,
     "color": ["red": red, "green": green, "blue": blue, "alpha": 1.0]]
  }

  private func pixel(_ image: UIImage) -> [UInt8] {
    let cg = image.cgImage!
    var bytes = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
    let context = CGContext(data: &bytes, width: cg.width, height: cg.height,
      bitsPerComponent: 8, bytesPerRow: cg.width * 4,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
    let index = ((cg.height / 2) * cg.width + cg.width / 2) * 4
    return Array(bytes[index..<(index + 4)])
  }

  private func assertSourceAndTintOrdering(_ kind: Kind) {
    let first = "https://artworkorder.invalid/\(UUID().uuidString).png"
    let stale = "https://artworkorder.invalid/\(UUID().uuidString).png"
    let latest = "https://artworkorder.invalid/\(UUID().uuidString).png"
    let blue = customTint(red: 0, green: 0, blue: 255)
    let green = customTint(red: 0, green: 255, blue: 0)
    let model = target(kind, payload(first))
    awaitRequest(first)
    model.update(payload(stale, tint: blue))
    awaitRequest(stale)
    model.update(payload(latest, tint: green))
    awaitRequest(latest)
    finish(latest, kind: kind, fraction: 1, tint: green)
    XCTAssertGreaterThan(pixel(model.read()!)[1], 240, "Newest tint was not applied")
    XCTAssertEqual(model.read()!.renderingMode, .alwaysOriginal)
    let newest = model.read()!.pngData()
    finish(stale, kind: kind, fraction: 1, tint: blue)
    XCTAssertEqual(model.read()!.pngData(), newest, "\(kind): stale source/tint update applied")
    finish(first, kind: kind, fraction: 1)
    XCTAssertEqual(model.read()!.pngData(), newest, "\(kind): late initial get applied")
  }

  func testPrimaryRejectsStaleSourceAndTint() { assertSourceAndTintOrdering(.primary) }
  func testTrailingRejectsStaleSourceAndTint() { assertSourceAndTintOrdering(.trailing) }
  func testCardRejectsStaleSourceAndTint() { assertSourceAndTintOrdering(.card) }
  func testCondensedRejectsStaleSourceAndTint() { assertSourceAndTintOrdering(.condensed) }
  func testGridRejectsStaleSourceAndTint() { assertSourceAndTintOrdering(.grid) }
  func testImageGridRejectsStaleSourceAndTint() { assertSourceAndTintOrdering(.imageGrid) }
  func testRowRejectsStaleSourceAndTint() { assertSourceAndTintOrdering(.row) }

  func testTintOnlyOverlappingRequestsForEveryArtworkProperty() {
    for kind in Kind.allCases {
      let source = "https://artworkorder.invalid/\(UUID().uuidString).png"
      var initial = payload(source)
      initial["imageData"] = FlutterStandardTypedData(bytes: artwork(.red).pngData()!)
      let model = target(kind, initial)
      let blue = customTint(red: 0, green: 0, blue: 255)
      let green = customTint(red: 0, green: 255, blue: 0)
      model.update(payload(source, tint: blue))
      awaitRequest(source)
      model.update(payload(source, tint: green))
      awaitRequest(source, count: 2)
      finish(source, kind: kind, fraction: 1, tint: green, index: 1)
      let newest = model.read()!.pngData()
      finish(source, kind: kind, fraction: 1, tint: blue)
      XCTAssertEqual(model.read()!.pngData(), newest, "\(kind): stale tint applied")
    }
  }

  func testReturningToSameSourceRejectsItsEarlierGeneration() {
    for kind in Kind.allCases {
      let first = "https://artworkorder.invalid/\(UUID().uuidString).png"
      let second = "https://artworkorder.invalid/\(UUID().uuidString).png"
      let model = target(kind, payload(first))
      awaitRequest(first)
      model.update(payload(second))
      awaitRequest(second)
      model.update(payload(first))
      awaitRequest(first, count: 2)
      finish(first, kind: kind, fraction: 1, color: .green, index: 1)
      let newest = model.read()!.pngData()
      finish(first, kind: kind, fraction: 1, color: .red)
      XCTAssertEqual(model.read()!.pngData(), newest, "\(kind): identity match accepted stale generation")
      finish(second, kind: kind, fraction: 1, color: .blue)
      XCTAssertEqual(model.read()!.pngData(), newest)
    }
  }

  func testClearedListImagesCannotBeResurrectedByPendingLoads() {
    for kind in [Kind.primary, .trailing] {
      let source = "https://artworkorder.invalid/\(UUID().uuidString).png"
      let model = target(kind, payload(source))
      awaitRequest(source)
      model.update(["image": NSNull()])
      XCTAssertNil(model.read())
      finish(source, kind: kind, fraction: 1)
      XCTAssertNil(model.read(), "\(kind): cleared artwork was resurrected")
    }
  }

  func testPrimaryAndTrailingGenerationsAreIndependent() {
    let primary = "https://artworkorder.invalid/\(UUID().uuidString).png"
    let trailing = "https://artworkorder.invalid/\(UUID().uuidString).png"
    let replacement = "https://artworkorder.invalid/\(UUID().uuidString).png"
    var initial = payload(primary)
    initial["trailingImage"] = trailing
    initial["trailingImageSize"] = ["fraction": 1.0]
    let model = FCPListItem(obj: initial)
    let native = model.get as! CPListItem
    awaitRequest(primary)
    awaitRequest(trailing)
    model.update(args: payload(replacement))
    awaitRequest(replacement)
    finish(trailing, kind: .trailing, fraction: 1, color: .blue)
    XCTAssertGreaterThan(pixel(native.accessoryImage!)[2], 240)
    finish(replacement, kind: .primary, fraction: 1, color: .green)
    let newest = native.image!.pngData()
    finish(primary, kind: .primary, fraction: 1)
    XCTAssertEqual(native.image!.pngData(), newest)
    XCTAssertGreaterThan(pixel(native.accessoryImage!)[2], 240)
  }

  func testSynchronousBytesChangesAndCacheHitsApplyForEveryArtworkProperty() {
    for kind in Kind.allCases {
      let source = "https://artworkorder.invalid/\(UUID().uuidString).png"
      var initial = payload(source)
      initial["imageData"] = FlutterStandardTypedData(bytes: artwork(.red).pngData()!)
      let model = target(kind, initial)
      XCTAssertGreaterThan(pixel(model.read()!)[0], 240)
      var changed = initial
      changed["imageData"] = FlutterStandardTypedData(bytes: artwork(.blue).pngData()!)
      model.update(changed)
      XCTAssertGreaterThan(pixel(model.read()!)[2], 240, "\(kind): changed bytes for the same path ignored")
      // A second wrapper must synchronously receive the prepared cache hit.
      let cached = target(kind, changed)
      XCTAssertEqual(cached.read()!.pngData(), model.read()!.pngData())
      XCTAssertEqual(OrderedArtworkProtocol.count(source), 0)
    }
  }

  func testPendingImageUpdatesDoNotRetainWrappersOrMutateReleasedOwners() {
    for kind in Kind.allCases {
      let source = "https://artworkorder.invalid/\(UUID().uuidString).png"
      let replacement = "https://artworkorder.invalid/\(UUID().uuidString).png"
      weak var owner: AnyObject?
      var read: (() -> UIImage?)!
      autoreleasepool {
        let model = target(kind, payload(source))
        owner = model.owner
        read = model.read
        model.update(payload(replacement))
      }
      awaitRequest(source)
      awaitRequest(replacement)
      XCTAssertNil(owner, "\(kind): pending artwork or native handler retained wrapper")
      let placeholder = read()!.pngData()
      finish(replacement, kind: kind, fraction: 1)
      finish(source, kind: kind, fraction: 1)
      XCTAssertEqual(read()!.pngData(), placeholder, "Released owner must not apply artwork")
    }
  }


  private func recreatedImage(_ kind: Kind, owner: AnyObject) -> () -> UIImage? {
    switch kind {
    case .primary, .trailing:
      let native = (owner as! FCPListItem).get as! CPListItem
      return { kind == .primary ? native.image : native.accessoryImage }
    case .card:
      let native = (owner as! FCPListImageRowItemCardElement).get as! CPListImageRowItemCardElement
      return { native.image }
    case .condensed:
      let native = (owner as! FCPListImageRowItemCondensedElement).get as! CPListImageRowItemCondensedElement
      return { native.image }
    case .grid:
      let native = (owner as! FCPListImageRowItemGridElement).get as! CPListImageRowItemGridElement
      return { native.image }
    case .imageGrid:
      let native = (owner as! FCPListImageRowItemImageGridElement).get as! CPListImageRowItemImageGridElement
      return { native.image }
    case .row:
      let native = (owner as! FCPListImageRowItemRowElement).get as! CPListImageRowItemRowElement
      return { native.image }
    }
  }

  func testRecreatedNativeTargetsRejectPriorGetCompletions() {
    for kind in Kind.allCases {
      let source = "https://artworkorder.invalid/\(UUID().uuidString).png"
      let model = target(kind, payload(source))
      awaitRequest(source)
      let oldPlaceholder = model.read()!.pngData()
      let current = recreatedImage(kind, owner: model.owner)
      awaitRequest(source, count: 2)
      finish(source, kind: kind, fraction: 1, color: .green, index: 1)
      let newest = current()!.pngData()
      finish(source, kind: kind, fraction: 1)
      XCTAssertEqual(current()!.pngData(), newest)
      XCTAssertEqual(model.read()!.pngData(), oldPlaceholder,
                     "\(kind): obsolete native target received its initial completion")
    }
  }

  func testListSelectionCompletionsSurviveWeakHandlerOwnership() {
    var model: FCPListItem? = FCPListItem(obj: ["_elementId": "selection", "onPress": true])
    let native = model!.get as! CPListItem
    var completions = 0
    native.handler?(native) { completions += 1 }
    XCTAssertEqual(completions, 0)
    model!.stopHandler()
    model!.stopHandler()
    XCTAssertEqual(completions, 1)
    model = nil
    native.handler?(native) { completions += 1 }
    XCTAssertEqual(completions, 2, "A detached handler must still complete selection")
  }

  func testReleasingAnActiveSelectionCompletesItsPendingHandler() {
    var model: FCPListItem? = FCPListItem(obj: ["_elementId": "selection", "onPress": true])
    weak var owner = model
    let native = model!.get as! CPListItem
    var completions = 0
    native.handler?(native) { completions += 1 }
    XCTAssertEqual(completions, 0)
    model = nil
    XCTAssertNil(owner)
    XCTAssertEqual(completions, 1, "Released selection must complete without a Dart reply")
    native.handler?(native) { completions += 1 }
    XCTAssertEqual(completions, 2)
  }

  func testStaleCompletionsCannotReplaceCacheHitsForLaterNativeTargets() {
    for kind in Kind.allCases {
      let source = "https://artworkorder.invalid/\(UUID().uuidString).png"
      let slot = FCPImageSlot.element(kind.maxSize, FCPImageSize(fraction: 1))
      let oldFinished = expectation(description: "old request finished")
      let latestFinished = expectation(description: "latest request finished")
      loadUIImage(from: source, bytes: nil, slot: slot) { _ in oldFinished.fulfill() }
      loadUIImage(from: source, bytes: nil, slot: slot) { _ in latestFinished.fulfill() }
      awaitRequest(source, count: 2)
      OrderedArtworkProtocol.finish(source, data: artwork(.green).pngData()!, index: 1)
      wait(for: [latestFinished], timeout: 5)
      let key = fcpPreparedImageCacheKey(imagePath: source, imageData: nil, slot: slot, tint: nil)
      let newest = fcpPreparedImageCache.object(forKey: key as NSString)!.pngData()
      OrderedArtworkProtocol.finish(source, data: artwork(.red).pngData()!)
      wait(for: [oldFinished], timeout: 5)
      XCTAssertEqual(fcpPreparedImageCache.object(forKey: key as NSString)!.pngData(), newest,
                     "Stale request overwrote the shared cache for \(kind)")
      let later = target(kind, payload(source))
      XCTAssertGreaterThan(pixel(later.read()!)[1], 240, "Later target used stale cached artwork")
      XCTAssertEqual(OrderedArtworkProtocol.count(source), 0)
      XCTAssertNil(fcpPreparedImageLoads[key], "Completed requests must release bookkeeping")
    }
  }

  func testClearingCacheInvalidatesPendingLoads() {
    let source = "https://artworkorder.invalid/\(UUID().uuidString).png"
    let slot = FCPImageSlot.listItem(FCPImageSize(fraction: 1))
    let completed = expectation(description: "pending request completes")
    loadUIImage(from: source, bytes: nil, slot: slot) { _ in completed.fulfill() }
    awaitRequest(source)
    fcpClearPreparedImageCache()
    OrderedArtworkProtocol.finish(source, data: artwork(.green).pngData()!)
    wait(for: [completed], timeout: 5)
    let key = fcpPreparedImageCacheKey(imagePath: source, imageData: nil, slot: slot, tint: nil)
    XCTAssertNil(fcpPreparedImageCache.object(forKey: key as NSString))
    XCTAssertNil(fcpPreparedImageLoads[key])
  }

  func testBackgroundUpdatesApplyRealArtworkOnMainQueue() {
    for kind in Kind.allCases {
      let source = "https://artworkorder.invalid/\(UUID().uuidString).png"
      let model = target(kind, payload(source))
      awaitRequest(source)
      let update = payload(source, fraction: 0.5)
      let submitted = expectation(description: "background update submitted")
      DispatchQueue.global().async { model.update(update); submitted.fulfill() }
      wait(for: [submitted], timeout: 5)
      awaitRequest(source, count: 2)
      finish(source, kind: kind, fraction: 0.5, color: .blue, index: 1)
      XCTAssertGreaterThan(pixel(model.read()!)[2], 240)
      let newest = model.read()!.pngData()
      finish(source, kind: kind, fraction: 1)
      XCTAssertEqual(model.read()!.pngData(), newest)
    }
  }
}

