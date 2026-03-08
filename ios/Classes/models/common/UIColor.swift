import UIKit

extension UIColor {
  convenience init?(from dict: [String: Any]) {
    guard let red = dict["red"] as? CGFloat,
      let green = dict["green"] as? CGFloat,
      let blue = dict["blue"] as? CGFloat,
      let alpha = dict["alpha"] as? CGFloat
    else { return nil }

    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}
