import CarPlay
import Flutter

/// Validates the channel contract before constructing any CarPlay objects.
@available(iOS 14.0, *)
final class FCPVoiceControlTemplate {
  let elementId: String
  private let states: [[String: Any]]
  private let leading: [[String: Any]]
  private let trailing: [[String: Any]]

  init(obj: [String: Any]) throws {
    elementId = try Self.string(obj, "_elementId")
    guard obj["runtimeType"] as? String == "FCPVoiceControlTemplate",
      let states = obj["voiceControlStates"] as? [[String: Any]],
      (1...5).contains(states.count)
    else { throw Self.invalid("Provide one to five voice control states.") }
    self.states = states
    leading = try Self.buttons(obj, "leadingNavigationBarButtons")
    trailing = try Self.buttons(obj, "trailingNavigationBarButtons")
    var identifiers = Set<String>()
    var actionDefinitions: [String: NSDictionary] = [:]
    for state in states {
      let identifier = try Self.string(state, "identifier")
      guard state["runtimeType"] as? String == "FCPVoiceControlState",
        identifiers.insert(identifier).inserted, Self.boolValue(state["repeats"]) != nil
      else {
        throw Self.invalid("Voice states require distinct identifiers and a repeats boolean.")
      }
      if let value = state["titleVariants"], !(value is NSNull) {
        guard let titles = value as? [String], !titles.isEmpty,
          titles.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else { throw Self.invalid("Title variants must contain nonempty strings.") }
      }
      try Self.validateImage(state, required: false)
      let buttons = try Self.buttons(state, "actionButtons")
      var stateButtons = Set<String>()
      for button in buttons {
        let id = try Self.string(button, "_elementId")
        guard button["runtimeType"] as? String == "FCPButton",
          Self.boolValue(button["isEnabled"]) != nil,
          stateButtons.insert(id).inserted
        else {
          throw Self.invalid("Action buttons require distinct identifiers and an enabled boolean.")
        }
        try Self.validateImage(button, required: true)
        if let title = button["title"], !(title is NSNull) { _ = try Self.string(button, "title") }
        if let previous = actionDefinitions[id], !previous.isEqual(to: button) {
          throw Self.invalid("A button identifier must describe a single button.")
        }
        actionDefinitions[id] = button as NSDictionary
      }
    }
    var barIds = Set<String>()
    for button in leading + trailing {
      let id = try Self.string(button, "_elementId")
      _ = try Self.string(button, "title")
      guard button["runtimeType"] as? String == "FCPBarButton",
        ["rounded", "none"].contains(button["buttonStyle"] as? String ?? ""),
        barIds.insert(id).inserted, actionDefinitions[id] == nil
      else {
        throw Self.invalid("Navigation buttons require distinct identifiers and a valid style.")
      }
    }
    if !leading.isEmpty || !trailing.isEmpty || !actionDefinitions.isEmpty {
      #if compiler(>=6.3)
        guard #available(iOS 26.4, *) else { throw Self.unsupportedControls() }
      #else
        throw Self.unsupportedControls()
      #endif
    }
  }

  /// Loads every state and action image before making the template presentable.
  func build(
    onButton: @escaping (String, String?) -> Void,
    completion: @escaping (Result<CPVoiceControlTemplate, Error>) -> Void
  ) {
    let group = DispatchGroup()
    var images: [String: UIImage] = [:]
    var failure: Error?
    func load(_ obj: [String: Any], key: String) {
      guard let path = obj["image"] as? String else { return }
      group.enter()
      if let image = makeUIImage(fromBytes: obj["imageData"] as? FlutterStandardTypedData) {
        images[key] = image
        group.leave()
        return
      }
      let source: ImageSource
      if path.hasPrefix("https://") || path.hasPrefix("http://"), let url = URL(string: path) {
        source = .url(url)
      } else if path.hasPrefix("file://"), let url = URL(string: path) {
        source = .file(url.path)
      } else {
        source = .flutterAsset(path)
      }
      loadUIImageAsync(
        from: source,
        completion: { image in
          images[key] = image
          group.leave()
        }, errorCallback: { error in failure = error })
    }
    for (index, state) in states.enumerated() {
      load(state, key: "state.\(index)")
      for button in state["actionButtons"] as? [[String: Any]] ?? [] {
        load(button, key: "button.\(button["_elementId"] as? String ?? "")")
      }
    }
    group.notify(queue: .main) { [self] in
      if let failure = failure {
        completion(.failure(failure))
        return
      }
      let nativeStates = states.enumerated().map { index, state in
        let identifier = state["identifier"] as? String ?? ""
        let native = CPVoiceControlState(
          identifier: identifier, titleVariants: state["titleVariants"] as? [String],
          image: Self.fit(images["state.\(index)"], to: CGSize(width: 150, height: 150)),
          repeats: state["repeats"] as? Bool ?? false)
        #if compiler(>=6.3)
          if #available(iOS 26.4, *) {
            native.actionButtons = (state["actionButtons"] as? [[String: Any]] ?? []).compactMap {
              obj in
              let id = obj["_elementId"] as? String ?? ""
              guard let image = images["button.\(id)"] else { return nil }
              let button = CPButton(image: Self.fit(image, to: CPButtonMaximumImageSize) ?? image) {
                _ in
                onButton(id, identifier)
              }
              button.title = obj["title"] as? String
              button.isEnabled = obj["isEnabled"] as? Bool ?? true
              return button
            }
          }
        #endif
        return native
      }
      let template = CPVoiceControlTemplate(voiceControlStates: nativeStates)
      template.elementId = elementId
      #if compiler(>=6.3)
        if #available(iOS 26.4, *) {
          func bar(_ obj: [String: Any]) -> CPBarButton {
            let id = obj["_elementId"] as? String ?? ""
            let button = CPBarButton(title: obj["title"] as? String ?? "") { _ in onButton(id, nil)
            }
            button.buttonStyle = obj["buttonStyle"] as? String == "none" ? .none : .rounded
            return button
          }
          template.leadingNavigationBarButtons = leading.map(bar)
          template.trailingNavigationBarButtons = trailing.map(bar)
        }
      #endif
      completion(.success(template))
    }
  }

  private static func fit(_ image: UIImage?, to maximum: CGSize) -> UIImage? {
    guard let image = image, image.size.width > 0, image.size.height > 0 else { return image }
    let scale = min(maximum.width / image.size.width, maximum.height / image.size.height)
    guard scale < 1 else { return image }
    if let frames = image.images {
      return UIImage.animatedImage(
        with: frames.compactMap { fit($0, to: maximum) }, duration: image.duration)
    }
    return image.resizeImageTo(
      size: CGSize(width: image.size.width * scale, height: image.size.height * scale)
    )
    .withRenderingMode(image.renderingMode)
  }

  static func boolValue(_ value: Any?) -> Bool? {
    guard let number = value as? NSNumber,
      CFGetTypeID(number) == CFBooleanGetTypeID()
    else { return nil }
    return number.boolValue
  }

  private static func string(_ obj: [String: Any], _ key: String) throws -> String {
    guard let value = obj[key] as? String,
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { throw invalid("\(key) must be a nonempty string.") }
    return value
  }

  private static func buttons(_ obj: [String: Any], _ key: String) throws -> [[String: Any]] {
    guard let buttons = obj[key] as? [[String: Any]] else {
      throw invalid("\(key) must contain an array of buttons.")
    }
    var maximum = 2 // CarPlay navigation bar limit per side.
    if key == "actionButtons" && !buttons.isEmpty {
      #if compiler(>=6.3)
        guard #available(iOS 26.4, *) else { throw unsupportedControls() }
        maximum = CPVoiceControlState.maximumActionButtonCount
      #else
        throw unsupportedControls()
      #endif
    }
    guard buttons.count <= maximum else {
      throw invalid("\(key) must contain at most \(maximum) buttons.")
    }
    return buttons
  }

  private static func validateImage(_ obj: [String: Any], required: Bool) throws {
    if !required && (obj["image"] == nil || obj["image"] is NSNull) { return }
    let path = try string(obj, "image")
    if path.contains("://") {
      guard let url = URL(string: path), let scheme = url.scheme,
        ["http", "https", "file"].contains(scheme),
        scheme == "file" ? !url.path.isEmpty : !(url.host ?? "").isEmpty
      else { throw invalid("Image URLs must be valid HTTP, HTTPS or file URLs.") }
    }
    if let bytes = obj["imageData"], !(bytes is FlutterStandardTypedData) {
      throw invalid("imageData must contain typed image bytes.")
    }
  }

  static func invalid(_ message: String) -> NSError {
    NSError(domain: "invalid_argument", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
  }

  private static func unsupportedControls() -> NSError {
    NSError(
      domain: "unsupported_version", code: 1,
      userInfo: [
        NSLocalizedDescriptionKey:
          "Voice action and navigation buttons require iOS 26.4 and Xcode 26.4 or later."
      ])
  }
}
