// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "zkp_client",
	platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "zkp-client",
            targets: ["zkp-client"]),
    ],
	dependencies: [
		.package(url: "https://github.com/attaswift/BigInt.git", exact: "5.3.0")
	],
    targets: [
        .target(
			name: "zkp-client", dependencies: ["BigInt"]),
        .testTarget(
            name: "zkp-clientTests",
            dependencies: ["zkp-client"]),
    ]
)
