import CarPlay

public protocol FCPTemplate {
  var get: CPTemplate { get }
  var elementId: String { get }
  func update(with: any FCPTemplate)
}
