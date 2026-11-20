// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "chytanka",
  platforms: [.macOS(.v14)],
  targets: [
    .target(name: "ChytankaCore"),
    .executableTarget(name: "chytanka", dependencies: ["ChytankaCore"]),
    .testTarget(name: "ChytankaCoreTests", dependencies: ["ChytankaCore"]),
  ]
)
