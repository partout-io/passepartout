// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "app-cross",
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
    ]
)

let swiftSettings: [SwiftSetting] = [
    .define("PSP_ABI", .when(platforms: [.android, .linux, .macOS, .windows])),
    .define("PSP_CROSS", .when(platforms: [.android, .linux, .windows]))
]

// MARK: Main

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
        ],
        swiftSettings: swiftSettings
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
            list.append("CommonLibrary_C")
            list.append("CommonProviders")
            return list
        }(),
        swiftSettings: swiftSettings
    ),
    .target(
        name: "CommonLibrary_C"
    ),
    .testTarget(
        name: "CommonLibraryTests",
        dependencies: ["CommonLibrary"],
        resources: [
            .process("Resources")
        ],
        swiftSettings: swiftSettings
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

// MARK: Cross-platform app (development)

import Foundation

if !ProcessInfo.processInfo.environment.keys.contains("FOR_TESTING") {
    let wxWidgetsVersion = "3.3"
    package.targets.append(contentsOf: [
        .target(
            name: "passepartout-shared",
            path: "passepartout/shared",
            resources: [.copy("assets")]
        ),
        .executableTarget(
            name: "passepartout",
            dependencies: [
                "CommonLibrary",
                "passepartout-shared"
            ],
            path: "passepartout/app",
            cxxSettings: [
                .unsafeFlags([
                    "-D__WXOSX_COCOA__",
                    "-D_FILE_OFFSET_BITS=64",
                    "-DwxDEBUG_LEVEL=0",
                    "-I/opt/homebrew/opt/wxwidgets/include/wx-\(wxWidgetsVersion)",
                    "-I/opt/homebrew/opt/wxwidgets/lib/wx/include/osx_cocoa-unicode-\(wxWidgetsVersion)"
                ]),
                .define("USE_SWIFTPM")
            ],
            linkerSettings: [
                .unsafeFlags(["-L/opt/homebrew/lib"]),
                .linkedFramework("IOKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("Cocoa"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("System"),
                .linkedFramework("OpenGL"),
                .linkedLibrary("wx_osx_cocoau_xrc-\(wxWidgetsVersion)"),
                .linkedLibrary("wx_osx_cocoau_html-\(wxWidgetsVersion)"),
                .linkedLibrary("wx_osx_cocoau_qa-\(wxWidgetsVersion)"),
                .linkedLibrary("wx_osx_cocoau_core-\(wxWidgetsVersion)"),
                .linkedLibrary("wx_baseu_xml-\(wxWidgetsVersion)"),
                .linkedLibrary("wx_baseu_net-\(wxWidgetsVersion)"),
                .linkedLibrary("wx_baseu-\(wxWidgetsVersion)")
            ]
        ),
        .executableTarget(
            name: "passepartout-tunnel",
            dependencies: [
                "CommonLibrary",
                "passepartout-shared"
            ],
            path: "passepartout/tunnel",
            cSettings: [.define("USE_SWIFTPM")]
        )
    ])
}
