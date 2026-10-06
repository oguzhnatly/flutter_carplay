import CarPlay
import Flutter
import XCTest

@available(iOS 26.0, *)
final class GridButtonTests: XCTestCase {
  private func payload() -> [String: Any] {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24), format: format).image { _ in
      UIColor.red.setFill()
      UIRectFill(CGRect(x: 0, y: 0, width: 24, height: 24))
    }
    return ["_elementId": "button", "titleVariants": ["Test"], "image": "fixture.png",
      "imageData": FlutterStandardTypedData(bytes: image.pngData()!), "onPress": true, "usesLoading": true]
  }

  func testRotationPreservesColorRenderingAndPixelScale() {
    let button = FCPGridButton(obj: payload())
    let native = button.get
    let original = native.image
    button.startLoadingRotation()
    XCTAssertEqual(native.image.renderingMode, original.renderingMode)
    let frames = Mirror(reflecting: button).children.first { $0.label == "rotationFrames" }!.value as! [UIImage]
    let source = Mirror(reflecting: button).children.first { $0.label == "rotationFramesSource" }!.value as! UIImage
    // CPGridButton normalizes scale in its getter. Test the renderer directly.
    XCTAssertEqual(frames.first!.scale, source.scale)
    XCTAssertEqual(frames.first!.cgImage!.width, source.cgImage!.width)
    button.stopLoadingRotation()
  }

  func testRetainedNativeButtonDoesNotRetainItsWrapper() {
    weak var weakButton: FCPGridButton?
    var native: CPGridButton?
    autoreleasepool {
      let button = FCPGridButton(obj: payload())
      weakButton = button
      native = button.get
      button.startLoadingRotation()
    }
    XCTAssertNil(weakButton)
    XCTAssertNotNil(native)
  }

  func testLateLoadingImageReplacesActiveFramesButNotCompletedImage() {
    var data = payload()
    data["loadingImage"] = "https://example.invalid/loading.png"
    var finish: ((UIImage) -> Void)!
    let button = FCPGridButton(obj: data, imageLoader: { _, _, _, completion in finish = completion })
    let native = button.get
    button.startLoadingRotation()
    let loading = UIImage(systemName: "hourglass")!.withRenderingMode(.alwaysOriginal)
    finish(loading)
    let source = Mirror(reflecting: button).children.first { $0.label == "rotationFramesSource" }!.value as! UIImage
    XCTAssertTrue(source === loading)
    button.stopLoadingRotation()
    let restored = native.image.pngData()
    finish(UIImage(systemName: "star")!)
    XCTAssertEqual(native.image.pngData(), restored)
  }

  func testDetachInvalidatesLoadingAndLateCompletions() {
    var data = payload()
    data["loadingImage"] = "https://example.invalid/loading.png"
    var finish: ((UIImage) -> Void)!
    let button = FCPGridButton(obj: data, imageLoader: { _, _, _, completion in finish = completion })
    let native = button.get
    button.startLoadingRotation()
    button.setVisible(false)
    let detachedImage = native.image.pngData()
    finish(UIImage(systemName: "star")!)
    XCTAssertEqual(native.image.pngData(), detachedImage)
    let link = Mirror(reflecting: button).children.first { $0.label == "rotationDisplayLink" }!.value as! CADisplayLink?
    XCTAssertNil(link)
  }

  func testStalePressCannotCompleteTheNextInteraction() {
    let button = FCPGridButton(obj: payload())
    let native = button.get
    button.handlePress()
    let first = button.activePressId!
    button.setVisible(false)
    button.setVisible(true)
    button.handlePress()
    let next = button.activePressId!
    XCTAssertNotEqual(first, next)
    XCTAssertFalse(button.completePress(pressId: first))
    XCTAssertEqual(button.activePressId, next)
    XCTAssertTrue(button.completePress(pressId: next))
    XCTAssertNil(button.activePressId)
  }

  func testLateNormalImageBecomesTheRestoredImage() {
    var data = payload()
    data.removeValue(forKey: "imageData")
    data["image"] = "https://example.invalid/normal.png"
    var finish: ((UIImage) -> Void)!
    let button = FCPGridButton(obj: data, imageLoader: { _, _, _, completion in finish = completion })
    let native = button.get
    button.startLoadingRotation()
    let original = UIImage(systemName: "star")!.withRenderingMode(.alwaysOriginal)
    finish(original)
    button.stopLoadingRotation()
    XCTAssertEqual(native.image.pngData(), original.pngData())
  }

  func testDisconnectCancelsNestedGridPress() {
    let grid = FCPGridTemplate(obj: ["_elementId": "grid", "title": "Grid", "showsTabBadge": false, "buttons": [payload()]])
    let tab = FCPTabBarTemplate(obj: ["_elementId": "tab", "showsTabBadge": false, "templates": []])
    _ = tab.get
    tab.updateTemplates(templates: [grid])
    SwiftFlutterCarplayPlugin.templateStack = [tab]
    let button = grid.getFCPGridButtons().first!
    button.handlePress()
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)
    XCTAssertNil(button.activePressId)
    SwiftFlutterCarplayPlugin.templateStack = []
  }

  func testSameIdGridReplacementCancelsOldPressAndUsesNewButtons() {
    let old = FCPGridTemplate(obj: ["_elementId": "grid", "title": "Grid", "showsTabBadge": false, "buttons": [payload()]])
    let tab = FCPTabBarTemplate(obj: ["_elementId": "tab", "showsTabBadge": false, "templates": []])
    _ = tab.get
    tab.updateTemplates(templates: [old])
    let oldButton = old.getFCPGridButtons().first!
    oldButton.handlePress()
    var data = payload()
    data["_elementId"] = "replacement"
    let replacement = FCPGridTemplate(obj: ["_elementId": "grid", "title": "Updated", "showsTabBadge": false, "buttons": [data]])
    tab.updateTemplates(templates: [replacement])
    XCTAssertNil(oldButton.activePressId)
    XCTAssertTrue((tab.getFCPTemplates().first as? FCPGridTemplate) === replacement)
    XCTAssertEqual((tab.getFCPTemplates().first as! FCPGridTemplate).getFCPGridButtons().first!.elementId, "replacement")
  }

  func testRemovedTabCancelsItsGridPress() {
    let grid = FCPGridTemplate(obj: ["_elementId": "grid", "title": "Grid", "showsTabBadge": false, "buttons": [payload()]])
    let tab = FCPTabBarTemplate(obj: ["_elementId": "tab", "showsTabBadge": false, "templates": []])
    _ = tab.get
    tab.updateTemplates(templates: [grid])
    let button = grid.getFCPGridButtons().first!
    button.handlePress()
    tab.updateTemplates(templates: [])
    XCTAssertNil(button.activePressId)
  }
}
