// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "StarOracleUIComponents",
  platforms: [
    .iOS(.v17),
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "StarOracleUIComponents",
      targets: ["StarOracleUIComponents"]
    ),
  ],
  dependencies: [
    .package(path: "../StarOracleCore")
  ],
  targets: [
    .target(
      name: "StarOracleUIComponents",
      dependencies: [
        .product(name: "StarOracleCore", package: "StarOracleCore")
      ]
    ),
    .testTarget(
      name: "StarOracleUIComponentsTests",
      dependencies: ["StarOracleUIComponents"]
    ),
  ]
)
