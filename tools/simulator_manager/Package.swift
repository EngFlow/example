// swift-tools-version:5.9

// Declares the external Swift packages that //tools/simulator_manager needs.
// rules_swift_package_manager resolves these into @swiftpkg_* repositories; the
// products are wired into the swift_binary in BUILD.bazel.

import PackageDescription

let package = Package(
    name: "simulator_manager",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.101.3"),
        .package(url: "https://github.com/apple/swift-nio-extras", from: "1.34.3"),
        .package(url: "https://github.com/JohnSundell/ShellOut", from: "2.3.0"),
    ]
)
