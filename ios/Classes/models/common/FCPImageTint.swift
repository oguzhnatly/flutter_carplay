import UIKit

struct FCPImageTint: Equatable {
  let type: String
  let color: UIColor?
  let darkColor: UIColor?
  let selectedSafe: Bool
  let cacheKey: String

  init?(from dict: [String: Any]?) {
    guard let dict = dict, let type = dict["type"] as? String else { return nil }
    self.type = type
    if let color = dict["color"] as? [String: Any] {
      self.color = UIColor(from: color)
    } else {
      self.color = nil
    }
    if let darkColor = dict["darkColor"] as? [String: Any] {
      self.darkColor = UIColor(from: darkColor)
    } else {
      self.darkColor = nil
    }
    self.selectedSafe = dict["selectedSafe"] as? Bool ?? true
    self.cacheKey = [
      type,
      FCPImageTint.colorKey(self.color),
      FCPImageTint.colorKey(self.darkColor),
      String(self.selectedSafe),
    ].joined(separator: "|")
  }

  static func == (lhs: FCPImageTint, rhs: FCPImageTint) -> Bool {
    lhs.cacheKey == rhs.cacheKey
  }

  func color(for style: UIUserInterfaceStyle) -> UIColor {
    switch type {
    case "platform":
      return UIColor.label
    case "primary":
      return UIColor.systemBlue
    case "secondary":
      return UIColor.systemTeal
    case "red":
      return UIColor.systemRed
    case "green":
      return UIColor.systemGreen
    case "blue":
      return UIColor.systemBlue
    case "yellow":
      return UIColor.systemYellow
    case "custom":
      if style == .dark, let darkColor = darkColor {
        return darkColor
      }
      return color ?? UIColor.label
    default:
      return UIColor.label
    }
  }

  private static func colorKey(_ color: UIColor?) -> String {
    guard let color = color else { return "nil" }
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return "\(red),\(green),\(blue),\(alpha)"
  }
}
