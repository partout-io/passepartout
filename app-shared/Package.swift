// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "app-shared",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "ABI",
            type: .dynamic,
            targets: ["ABI"]
        ),
        .library(
            name: "CommonLibrary",
            targets: ["CommonLibrary"]
        ),
        .library(
            name: "CommonProviders",
            targets: ["CommonProviders"]
        )
    ],
    dependencies: [
        .package(path: "../submodules/partout"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.83.0")
    ],
    targets: [
        .executableTarget(
            name: "ABIExample_C",
            dependencies: ["ABI"]
        ),
        .target(
            name: "ABI",
            dependencies: ["ABI_C"]
        ),
        .target(
            name: "ABI_C",
            dependencies: ["CommonLibrary"]
        ),
        .target(
            name: "CommonLibraryApple",
            dependencies: ["CommonLibraryCore"]
        ),
        .target(
            name: "CommonLibraryCore",
            dependencies: [
                .product(name: "NIO", package: "swift-nio", condition: .when(platforms: [.tvOS])),
                .product(name: "NIOHTTP1", package: "swift-nio", condition: .when(platforms: [.tvOS])),
                "CommonProviders",
                "partout"
            ],
            swiftSettings: [
                .define("PSP_DYNLIB", .when(platforms: [.android, .linux, .windows]))
            ]
        ),
        .target(
            name: "CommonLibrary",
            dependencies: [
                "CommonLibraryCore",
                .target(name: "CommonLibraryApple", condition: .when(platforms: [.iOS, .macOS, .tvOS]))
            ]
        ),
        .target(
            name: "CommonProviders",
            dependencies: ["CommonProvidersAPI"]
        ),
        .target(
            name: "CommonProvidersAPI",
            dependencies: ["CommonProvidersCore"],
            resources: [
                .copy("JSON")
            ]
        ),
        .target(
            name: "CommonProvidersCore",
            dependencies: ["partout"]
        ),
        .testTarget(
            name: "CommonLibraryTests",
            dependencies: ["CommonLibrary"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CommonProvidersTests",
            dependencies: ["CommonProviders"],
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "CommonProvidersAPITests",
            dependencies: ["CommonProvidersAPI"]
        ),
        .testTarget(
            name: "CommonProvidersCoreTests",
            dependencies: ["CommonProvidersCore"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
