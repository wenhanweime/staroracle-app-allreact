// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "StarOracleFeatures",
  platforms: [
    .iOS(.v17),
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "StarOracleFeatures",
      targets: ["StarOracleFeatures"]
    ),
  ],
  dependencies: [
    .package(path: "../StarOracleCore"),
    .package(path: "../StarOracleServices")
  ],
  targets: [
    .target(
      name: "StarOracleFeatures",
      dependencies: [
        .product(name: "StarOracleCore", package: "StarOracleCore"),
        .product(name: "StarOracleServices", package: "StarOracleServices")
      ]
    ),
    .testTarget(
      name: "StarOracleFeaturesTests",
      dependencies: ["StarOracleFeatures"]
    ),
  ]
)
