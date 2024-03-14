import Flutter
import heresdk
import os
import UIKit

let flutterEngine = FlutterEngine(name: "SharedEngine", project: nil, allowHeadlessExecution: true)

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(_ application: UIApplication,
                              didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        Logger.statistics.log("Initiate Flutter plugin run from AppDelegate")
        flutterEngine.run()
        GeneratedPluginRegistrant.register(with: flutterEngine)
        Logger.statistics.log("Flutter plugin ran from AppDelegate")
        initializeHERESDK()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func initializeHERESDK() {
        // Set your credentials for the HERE SDK.
        let accessKeyID = "<#accessKeyID#>"
        let accessKeySecret = "<#accessKeySecret#>"
        let options = SDKOptions(accessKeyId: accessKeyID, accessKeySecret: accessKeySecret)
        do {
            try SDKNativeEngine.makeSharedInstance(options: options)
        } catch let engineInstantiationError {
            fatalError("Failed to initialize the HERE SDK. Cause: \(engineInstantiationError)")
        }
    }
}

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// All logs related to tracking and analytics.
    static let statistics = Logger(subsystem: subsystem, category: "statistics")
}
