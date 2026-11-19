// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RushCore",
    products: [.library(name: "RushCore", targets: ["RushCore"])],
    targets: [
        .target(name: "RushCore"),
        .testTarget(name: "RushCoreTests", dependencies: ["RushCore"])
    ]
)
