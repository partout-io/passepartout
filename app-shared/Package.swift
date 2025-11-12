// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "AppAccessibility",
            targets: ["AppAccessibility"]
        ),
        .library(
            name: "AppLibrary",
            targets: ["AppLibrary"]
        ),
        .library(
            name: "AppLibraryMain",
            targets: [
                "CommonDataPreferences",
                "CommonDataProfiles",
                "CommonDataProviders",
                "AppLibraryMainWrapper"
            ]
        ),
        .library(
            name: "AppLibraryTV",
            targets: [
                "CommonDataPreferences",
                "CommonDataProfiles",
                "CommonDataProviders",
                "AppLibraryTVWrapper"
            ]
        ),
        .library(
            name: "CommonLibrary",
            targets: ["CommonLibrary"]
        ),
        .library(
            name: "CommonProviders",
            targets: ["CommonProviders"]
        ),
        .library(
            name: "CommonWeb",
            targets: ["CommonWeb"]
        ),
        .library(
            name: "PartoutLibrary",
            targets: ["PartoutLibrary"]
        ),
        .library(
            name: "TunnelLibrary",
            targets: ["CommonLibrary"]
        )
    ],
    dependencies: [
        .package(path: "../submodules/partout"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.83.0")
    ],
    targets: [
        .target(
            name: "AppAccessibility"
        ),
        .target(
            name: "AppLibrary",
            dependencies: [
                "CommonLibrary",
                "AppStrings",
                "AppAccessibility"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "AppLibraryMain",
            dependencies: ["AppLibrary"],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "AppLibraryMainWrapper",
            dependencies: [
                .target(name: "AppLibraryMain", condition: .when(platforms: [.iOS, .macOS]))
            ],
            path: "Sources/Empty/AppLibraryMainWrapper"
        ),
        .target(
            name: "AppLibraryTV",
            dependencies: [
                "AppLibrary",
                "CommonWeb"
            ]
        ),
        .target(
            name: "AppLibraryTVWrapper",
            dependencies: [
                .target(name: "AppLibraryTV", condition: .when(platforms: [.tvOS]))
            ],
            path: "Sources/Empty/AppLibraryTVWrapper"
        ),
        .target(
            name: "AppStrings",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "CommonData",
            dependencies: []
        ),
        .target(
            name: "CommonDataPreferences",
            dependencies: [
                "CommonData",
                "CommonLibrary"
            ],
            resources: [
                .process("Preferences.xcdatamodeld")
            ]
        ),
        .target(
            name: "CommonDataProfiles",
            dependencies: [
                "CommonData",
                "CommonLibrary"
            ],
            resources: [
                .process("Profiles.xcdatamodeld")
            ]
        ),
        .target(
            name: "CommonDataProviders",
            dependencies: [
                "CommonData",
                "CommonLibrary"
            ],
            resources: [
                .process("Providers.xcdatamodeld")
            ]
        ),
        .target(
            name: "CommonLibrary",
            dependencies: [
                "CommonProviders",
                "partout"
            ],
            resources: [
                .process("Resources")
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
        .target(
            name: "CommonWeb",
            dependencies: [
                "CommonLibrary",
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "PartoutLibrary",
            dependencies: ["partout"],
            path: "Sources/Empty/PartoutLibrary"
        ),
        .testTarget(
            name: "AppLibraryTests",
            dependencies: ["AppLibrary"]
        ),
        .testTarget(
            name: "AppLibraryMainTests",
            dependencies: ["AppLibraryMain"]
        ),
        .testTarget(
            name: "CommonLibraryTests",
            dependencies: ["CommonLibrary"]
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
        ),
        .testTarget(
            name: "CommonWebTests",
            dependencies: ["CommonWeb"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
