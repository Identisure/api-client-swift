// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IdkollenClient",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "IdkollenClient", targets: ["IdkollenClient"]),
    ],
    targets: [
        .target(name: "IdkollenClient"),
        .testTarget(
            name: "IdkollenClientTests",
            dependencies: ["IdkollenClient"]
        ),
    ]
)
