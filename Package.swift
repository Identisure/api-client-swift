// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IdentisureClient",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "IdentisureClient", targets: ["IdentisureClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", "3.0.0"..<"6.0.0"),
    ],
    targets: [
        .target(
            name: "IdentisureClient",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux])),
            ],
            path: "swift/Sources/IdentisureClient"
        ),
        .testTarget(
            name: "IdentisureClientTests",
            dependencies: ["IdentisureClient"],
            path: "swift/Tests/IdentisureClientTests"
        ),
    ]
)
