// swift-tools-version: 5.9
// Projet de cours — Théo BOREL et Lana SCHMITT.
// Permet de tester les règles avec la commande swift test.
import PackageDescription

let package = Package(
    name: "RushCore",
    products: [.library(name: "RushCore", targets: ["RushCore"])],
    targets: [
        .target(name: "RushCore"),
        .testTarget(name: "RushCoreTests", dependencies: ["RushCore"])
    ]
)
