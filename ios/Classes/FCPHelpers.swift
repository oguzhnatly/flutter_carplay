//
//  FCPHelpers.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

func getUIApplicationDelegate() -> SwiftFlutterCarplayPlugin? {
  return UIApplication.shared.delegate as? SwiftFlutterCarplayPlugin
}

var currentUIWindow: UIWindow? = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

func makeFCPChannelId(event: String?) -> String {
  return "com.oguzhnatly.flutter_carplay" + event!
}
