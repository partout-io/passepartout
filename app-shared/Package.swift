// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let withProviders = true
let swiftSettings = {
    var list: [SwiftSetting] = [
        .define("PSP_CROSS", .when(platforms: [.android, .linux, .windows]))
    ]
    if withProviders {
        list.append(.define("PSP_PROVIDERS"))
    }
    return list
}()

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
            name: "CommonLibrary",
            targets: ["CommonLibrary"]
        )
    ],
    dependencies: [
        .package(path: "../submodules/partout"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.83.0")
    ],
    targets: [
        .executableTarget(
            name: "CommonExample_C",
            dependencies: ["CommonLibrary_C"]
        ),
        .target(
            name: "CommonLibrary_C",
            dependencies: ["CommonLibrary"]
        ),
        .target(
            name: "CommonLibraryApple",
            dependencies: ["CommonLibraryCore"]
        ),
        .target(
            name: "CommonLibraryCore",
            dependencies: {
                var list: [Target.Dependency] = [
                    .product(name: "NIO", package: "swift-nio", condition: .when(platforms: [.tvOS])),
                    .product(name: "NIOHTTP1", package: "swift-nio", condition: .when(platforms: [.tvOS])),
                    "partout"
                ]
                if withProviders {
                    list.append(
                        .target(name: "CommonProviders")
                    )
                }
                return list
            }(),
            swiftSettings: swiftSettings
        ),
        .target(
            name: "CommonLibrary",
            dependencies: [
                "CommonLibraryCore",
                .target(name: "CommonLibraryApple", condition: .when(platforms: [.iOS, .macOS, .tvOS]))
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CommonLibraryTests",
            dependencies: ["CommonLibrary"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)

if withProviders {
    package.products.append(
        .library(
            name: "CommonProviders",
            targets: ["CommonProviders"]
        )
    )
    package.targets.append(contentsOf: [
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
    ])
}
