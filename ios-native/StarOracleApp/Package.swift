// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "StarOracleApp",
  platforms: [
    .iOS(.v17),
    .macOS(.v14)
  ],
  dependencies: [
    .package(path: "../Packages/StarOracleCore"),
    .package(path: "../Packages/StarOracleServices"),
    .package(path: "../Packages/StarOracleFeatures"),
    .package(path: "../Packages/StarOracleUIComponents")
  ],
  targets: [
    .executableTarget(
      name: "StarOracleApp",
      dependencies: [
        .product(name: "StarOracleCore", package: "StarOracleCore"),
        .product(name: "StarOracleServices", package: "StarOracleServices"),
        .product(name: "StarOracleFeatures", package: "StarOracleFeatures"),
        .product(name: "StarOracleUIComponents", package: "StarOracleUIComponents")
      ],
      swiftSettings: [
        .unsafeFlags(["-parse-as-library"], .when(platforms: [.iOS, .macOS]))
      ]
    ),
  ]
)
