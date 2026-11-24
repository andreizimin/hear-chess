// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "HearChessCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "HearChessCore", targets: ["HearChessCore"]),
    ],
    targets: [
        .target(name: "HearChessCore"),
        .testTarget(name: "HearChessCoreTests", dependencies: ["HearChessCore"]),
    ]
)
