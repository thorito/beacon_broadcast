// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "beacon_broadcast",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "beacon-broadcast", targets: ["beacon_broadcast", "BeaconBroadcastSwift"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "beacon_broadcast",
            dependencies: [
                "BeaconBroadcastSwift",
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            publicHeadersPath: "include"
        ),
        .target(
            name: "BeaconBroadcastSwift",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ]
        ),
    ]
)
