import CarPlay
import Foundation

@available(iOS 26.0, *)
public protocol FCPListImageRowItemElement {
  var image: String { get }
  var elementId: String { get }
  var get: CPListImageRowItemElement { get }
  func update(args: [String: Any])
}
