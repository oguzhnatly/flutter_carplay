import CarPlay
import Flutter

/// A narrow host boundary allows modal lifecycle tests without a connected car.
@available(iOS 14.0, *)
protocol FCPModalHost: AnyObject {
  var presentedTemplate: CPTemplate? { get }
  func presentTemplate(
    _ template: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)?)
  func dismissTemplate(animated: Bool, completion: ((Bool, Error?) -> Void)?)
}

@available(iOS 14.0, *)
extension CPInterfaceController: FCPModalHost {}

/// Owns a single modal reservation from image loading until dismissal.
@available(iOS 14.0, *)
final class FCPModalController {
  private weak var host: FCPModalHost?
  private var current: Request?
  var isConnected: Bool { host != nil }

  private final class Request {
    let id: String
    var template: CPTemplate?
    var owner: AnyObject?
    var presenting = false
    var cancelling = false
    var dismissing = false
    var notified = false
    var result: FlutterResult?
    var dismissResults: [FlutterResult] = []

    init(id: String, result: @escaping FlutterResult) {
      self.id = id
      self.result = result
    }

    func complete(_ value: Any) {
      let callback = result
      result = nil
      callback?(value)
    }
  }

  func connect(_ host: FCPModalHost?) {
    if let previous = current {
      current = nil
      notifyDismissal(previous)
      previous.complete(false)
      previous.dismissResults.forEach { $0(false) }
      previous.dismissResults.removeAll()
    }
    self.host = host
  }

  func showVoice(_ voice: FCPVoiceControlTemplate, animated: Bool, result: @escaping FlutterResult)
  {
    guard let request = reserve(id: voice.elementId, result: result) else { return }
    request.owner = voice
    voice.build(
      onButton: { [weak self, weak request] id, state in
        guard let self = self, let request = request, self.current === request,
          !request.cancelling, !request.presenting, !request.dismissing,
          let template = request.template as? CPVoiceControlTemplate,
          self.host?.presentedTemplate === template,
          state == nil || template.activeStateIdentifier == state
        else { return }
        FCPStreamHandlerPlugin.sendEvent(
          type: FCPChannelTypes.onVoiceControlButtonPressed,
          data: ["templateId": request.id, "elementId": id])
      },
      completion: { [weak self, weak request] built in
        guard let self = self, let request = request, self.current === request else { return }
        switch built {
        case .success(let template): self.present(template, request: request, animated: animated)
        case .failure(let error):
          self.current = nil
          request.complete(Self.flutterError(error))
        }
      })
  }

  func show(
    _ template: CPTemplate, owner: AnyObject, animated: Bool, result: @escaping FlutterResult
  ) {
    guard let id = template.elementId else {
      result(false)
      return
    }
    guard let request = reserve(id: id, result: result) else { return }
    request.owner = owner
    present(template, request: request, animated: animated)
  }

  private func reserve(id: String, result: @escaping FlutterResult) -> Request? {
    guard let host = host, current == nil, host.presentedTemplate == nil else {
      result(false)
      return nil
    }
    let request = Request(id: id, result: result)
    current = request
    return request
  }

  private func present(_ template: CPTemplate, request: Request, animated: Bool) {
    guard let host = host, current === request else {
      request.complete(false)
      return
    }
    request.template = template
    request.presenting = true
    // Supplying a completion lets CarPlay report unsupported category errors.
    host.presentTemplate(template, animated: animated) { [weak self, weak request] success, error in
      guard let self = self, let request = request, self.current === request else { return }
      request.presenting = false
      if request.cancelling {
        if success && error == nil && self.host?.presentedTemplate === template {
          self.dismiss(request, animated: animated)
        } else {
          self.finishDismissal(request, success: true)
        }
        return
      }
      guard success, error == nil, self.host?.presentedTemplate === template else {
        self.current = nil
        request.complete(error.map(Self.flutterError) ?? false)
        return
      }
      request.complete(true)
    }
  }

  func activate(elementId: String, identifier: String) -> Bool {
    guard let request = current, request.id == elementId,
      !request.presenting, !request.cancelling, !request.dismissing,
      let template = request.template as? CPVoiceControlTemplate,
      host?.presentedTemplate === template,
      template.voiceControlStates.contains(where: { $0.identifier == identifier })
    else { return false }
    template.activateVoiceControlState(withIdentifier: identifier)
    return template.activeStateIdentifier == identifier
  }

  func close(animated: Bool, result: @escaping FlutterResult) {
    guard let request = current, host != nil else {
      result(false)
      return
    }
    request.dismissResults.append(result)
    if request.dismissing || request.cancelling { return }
    if request.template == nil {
      finishDismissal(request, success: true)
    } else if request.presenting {
      request.cancelling = true
    } else {
      dismiss(request, animated: animated)
    }
  }

  private func dismiss(_ request: Request, animated: Bool) {
    request.dismissing = true
    host?.dismissTemplate(animated: animated) { [weak self, weak request] success, error in
      guard let self = self, let request = request, self.current === request else { return }
      self.finishDismissal(request, success: success && error == nil)
    }
  }

  private func finishDismissal(_ request: Request, success: Bool) {
    request.dismissing = false
    request.cancelling = false
    if success {
      current = nil
      notifyDismissal(request)
      request.complete(false)
    } else {
      // A failed cancellation leaves the actual presentation available for retry.
      request.complete(host?.presentedTemplate === request.template)
    }
    let callbacks = request.dismissResults
    request.dismissResults.removeAll()
    callbacks.forEach { $0(success) }
  }

  func didDisappear(_ template: CPTemplate) {
    guard let request = current, request.template === template,
      host?.presentedTemplate !== template
    else { return }
    finishDismissal(request, success: true)
  }

  private func notifyDismissal(_ request: Request) {
    guard !request.notified else { return }
    request.notified = true
    FCPStreamHandlerPlugin.sendEvent(
      type: FCPChannelTypes.onVoiceControlDismissed,
      data: ["elementId": request.id])
  }

  static func flutterError(_ error: Error) -> FlutterError {
    let error = error as NSError
    let code =
      ["invalid_argument", "unsupported_version"].contains(error.domain)
      ? error.domain : "carplay_error"
    return FlutterError(code: code, message: error.localizedDescription, details: nil)
  }
}
