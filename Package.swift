// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EasySweepCatalog",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "EasySweepCatalog", targets: ["EasySweepCatalog"])
    ],
    targets: [
        .target(
            name: "EasySweepCatalog",
            // `.copy`, not `.process`: the JSON must reach the bundle byte for
            // byte, and processing would be free to rewrite it.
            resources: [.copy("Catalog")]
        ),
        .testTarget(
            name: "EasySweepCatalogTests",
            dependencies: ["EasySweepCatalog"]
        ),
    ]
)
