// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "StarOracleCore",
  platforms: [
    .iOS(.v17),
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "StarOracleCore",
      targets: ["StarOracleCore"]
    ),
  ],
  targets: [
    .target(
      name: "StarOracleCore"
    ),
    .testTarget(
      name: "StarOracleCoreTests",
      dependencies: ["StarOracleCore"]
    ),
  ]
)
