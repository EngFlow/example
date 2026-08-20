// swift-tools-version: 5.9

import PackageDescription

// This manifest exists only so `rules_swift_package_manager` can resolve and vendor
// this daemon's third-party dependencies for Bazel (see the BUILD file in this
// directory). It declares no targets/products of its own -- the daemon is built as
// a `swift_binary` directly from these sources, not as a Swift package.
let package = Package(
  name: "macsimulatormanager",
  dependencies: [
    .package(url: "https://github.com/JohnSundell/ShellOut", from: "2.3.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
    .package(url: "https://github.com/apple/swift-nio-extras", from: "1.34.3"),
  ]
)
