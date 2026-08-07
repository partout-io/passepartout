// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let partoutNative: Target = .partoutNative(
    // .local
    .remote("0.154.5", checksum: "aba03cf660ab321d6d8ac8c2fe37ac739c2e05eda6d744731e680a054be23192")
)

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
            name: "PartoutNative",
            targets: ["PartoutNative"]
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
                "PartoutNative",
                .product(name: "PartoutRuntime", package: "partout")
            ]
        ),
        partoutNative,
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

enum PartoutNativeTarget {
    case local
    case remote(_ version: String, checksum: String)
}

extension Target {
    static func partoutNative(_ target: PartoutNativeTarget) -> Target {
        let name = "PartoutNative"
        switch target {
        case .local:
            return .binaryTarget(
                name: name,
                path: "\(name).xcframework"
            )
        case .remote(let version, let checksum):
            return .binaryTarget(
                name: name,
                url: "https://github.com/partout-io/partout/releases/download/\(version)/\(name).xcframework.zip",
                checksum: checksum
            )
        }
    }
}

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
        name: "CommonDataProviders",
        dependencies: ["CommonData"],
        resources: [
            .process("Providers.xcdatamodeld")
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
            "CommonDataProviders",
            "CommonLibraryCore"
        ]
    ),
    .target(
        name: "CommonLibraryCore",
        dependencies: {
            var list: [Target.Dependency] = [
                .product(name: "NIO", package: "swift-nio", condition: .when(platforms: [.tvOS])),
                .product(name: "NIOHTTP1", package: "swift-nio", condition: .when(platforms: [.tvOS])),
                "partout"
            ]
            list.append("CommonProviders")
            return list
        }()
    ),
    .testTarget(
        name: "CommonLibraryTests",
        dependencies: ["CommonLibrary"],
        resources: [
            .process("Resources")
        ]
    )
])

// MARK: Providers

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
    )
])
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
