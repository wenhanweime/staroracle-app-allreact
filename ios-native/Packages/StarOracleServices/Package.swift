// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "StarOracleServices",
  platforms: [
    .iOS(.v17),
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "StarOracleServices",
      targets: ["StarOracleServices"]
    ),
  ],
  dependencies: [
    .package(path: "../StarOracleCore")
  ],
  targets: [
    .target(
      name: "StarOracleServices",
      dependencies: [
        .product(name: "StarOracleCore", package: "StarOracleCore")
      ]
    ),
    .testTarget(
      name: "StarOracleServicesTests",
      dependencies: ["StarOracleServices"]
    ),
  ]
)
