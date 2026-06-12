// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_carplay",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(name: "flutter-carplay", targets: ["flutter_carplay"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_carplay",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/flutter_carplay",
            exclude: [
                "FlutterCarplayPlugin.m",
                "FlutterCarplayPlugin.h"
            ],
            linkerSettings: [
                .linkedFramework("CarPlay"),
                .linkedFramework("UIKit"),
                .linkedFramework("AVFoundation")
            ]
        )
    ]
)