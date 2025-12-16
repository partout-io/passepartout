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
            dependencies: ["CommonLibrary"]
        ),
        .target(
            name: "CommonLibrary",
            dependencies: [
                "CommonLibraryCore",
                .target(name: "CommonLibraryApple", condition: .when(platforms: [.iOS, .macOS, .tvOS]))
            ],
            swiftSettings: swiftSettings
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
                list.append("CommonLibraryCore_C")
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
            name: "CommonLibraryCore_C"
        ),
        .testTarget(
            name: "CommonLibraryTests",
            dependencies: ["CommonLibrary"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: swiftSettings
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
            dependencies: ["CommonProvidersAPI"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "CommonProvidersAPI",
            dependencies: ["CommonProvidersCore"],
            resources: [
                .copy("JSON")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "CommonProvidersCore",
            dependencies: ["partout"],
            swiftSettings: swiftSettings
        )
    ])
}

#if canImport(Darwin)
package.targets.append(contentsOf: [
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
    )
])
#endif
