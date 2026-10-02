// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// The "*Wrapper" targets only exist for testing

let package = Package(
    name: "app-apple",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
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
            targets: ["AppLibraryMain"]
        ),
        .library(
            name: "AppLibraryTV",
            targets: ["AppLibraryTV"]
        ),
        .library(
            name: "TunnelLibrary",
            targets: ["TunnelLibrary"]
        )
    ],
    targets: [
        .target(
            name: "AppAccessibility"
        ),
        .target(
            name: "AppLibrary",
            dependencies: [
                "AppAccessibility",
                "AppResources",
                "AppStrings"
            ]
        ),
        .target(
            name: "AppLibraryMain",
            dependencies: ["AppLibrary"]
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
            dependencies: ["AppLibrary"]
        ),
        .target(
            name: "AppLibraryTVWrapper",
            dependencies: [
                .target(name: "AppLibraryTV", condition: .when(platforms: [.tvOS]))
            ],
            path: "Sources/Empty/AppLibraryTVWrapper"
        ),
        .target(
            name: "AppResources",
            dependencies: ["CommonLibrary"],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "AppStrings",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "TunnelLibrary",
            dependencies: [
                "AppResources",
                "AppStrings",
                .product(name: "partout", package: "partout")
            ]
        ),
        .testTarget(
            name: "TunnelLibraryTests",
            dependencies: [
                "CommonLibrary",
                "TunnelLibrary",
                .product(name: "partout", package: "partout")
            ]
        ),
        .testTarget(
            name: "AppLibraryTests",
            dependencies: [
                "AppLibrary",
                "AppResources"
            ]
        ),
        .testTarget(
            name: "AppLibraryMainTests",
            dependencies: ["AppLibraryMainWrapper"]
        )
    ]
)

// MARK: - CommonLibrary*

package.products.append(
    .library(
        name: "CommonLibrary",
        targets: ["CommonLibrary"]
    )
)

package.dependencies.append(contentsOf: [
    .package(path: "../partout"),
    .package(url: "https://github.com/apple/swift-nio", from: "2.83.0")
])

package.targets.append(contentsOf: [
    .target(
        name: "CommonData",
        dependencies: ["CommonLibraryCore"]
    ),
    .target(
        name: "CommonDataPreferences",
        dependencies: ["CommonData"],
        resources: [
            .process("Preferences.xcdatamodeld")
        ]
    ),
    .target(
        name: "CommonDataProfiles",
        dependencies: ["CommonData"],
        resources: [
            .process("Profiles.xcdatamodeld")
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
        name: "CommonLibraryApple",
        dependencies: [
            "CommonDataPreferences",
            "CommonDataProfiles",
            "CommonLibraryCore"
        ]
    ),
    .target(
        name: "CommonLibraryCore",
        dependencies: [
            "partout",
            .product(name: "NIO", package: "swift-nio", condition: .when(platforms: [.tvOS])),
            .product(name: "NIOHTTP1", package: "swift-nio", condition: .when(platforms: [.tvOS]))
        ]
    ),
    .testTarget(
        name: "CommonLibraryTests",
        dependencies: ["CommonLibrary"],
        resources: [
            .process("Resources")
        ]
    )
])
