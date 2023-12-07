import Flutter
import UIKit

let flutterEngine = FlutterEngine(name: "SharedEngine", project: nil, allowHeadlessExecution: true)

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(_ application: UIApplication,
                              didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        flutterEngine.run()
        GeneratedPluginRegistrant.register(with: flutterEngine)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
