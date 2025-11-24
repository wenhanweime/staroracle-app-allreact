// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PixelPlanetsSwift",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "PixelPlanetsCore",
            targets: ["PixelPlanetsCore"]
        ),
        .executable(
            name: "PixelPlanetsSwiftCLI",
            targets: ["PixelPlanetsSwiftCLI"]
        ),
    ],
    targets: [
        .target(
            name: "PixelPlanetsCore",
            resources: [
                // Shaders contain duplicate filenames in subfolders; copy preserves structure.
                .copy("Shaders"),
            ]
        ),
        .executableTarget(
            name: "PixelPlanetsSwiftCLI",
            dependencies: ["PixelPlanetsCore"]
        ),
        .testTarget(
            name: "PixelPlanetsCoreTests",
            dependencies: ["PixelPlanetsCore"],
            path: "Tests/PixelPlanetsCoreTests"
        ),
    ]
)
