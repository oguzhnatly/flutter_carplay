import Flutter
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

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// All logs related to tracking and analytics.
    static let statistics = Logger(subsystem: subsystem, category: "statistics")
}
