import CarPlay
import Foundation

@available(iOS 14.0, *)
public protocol FCPListTemplateItem {
  var text: String? { get }
  var elementId: String { get }
  var get: CPListTemplateItem { get }
}
