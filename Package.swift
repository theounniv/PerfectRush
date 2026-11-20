// swift-tools-version: 5.9
// Projet de cours — Théo BOREL et Lana SCHMITT.
// Permet de tester les règles avec la commande swift test.
import PackageDescription

let package = Package(
    name: "RushCore",
    // CryptoKit (hash du nonce Apple) demande macOS 10.15 ou plus récent.
    platforms: [.macOS(.v12), .iOS(.v17), .watchOS(.v10)],
    products: [.library(name: "RushCore", targets: ["RushCore"])],
    targets: [
        .target(name: "RushCore"),
        .testTarget(name: "RushCoreTests", dependencies: ["RushCore"])
    ]
)
