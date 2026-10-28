// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TickTack",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "TickTack", targets: ["TickTack"])],
    targets: [
        .executableTarget(name: "TickTack"),
        .testTarget(name: "TickTackTests", dependencies: ["TickTack"], exclude: ["Fixtures"])
    ]
)
