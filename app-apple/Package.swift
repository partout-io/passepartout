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
            targets: ["AppResources"]
        ),
        .library(
            name: "AppPartoutRuntime",
            targets: ["AppPartoutRuntime"]
        )
    ],
    dependencies: [
        .package(path: "../partout"),
        .package(path: "../app-shared")
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
            dependencies: [
                .product(name: "CommonLibrary", package: "app-shared")
            ],
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
//        .target(
//            name: "AppPartoutRuntime",
//            dependencies: [
//                "PartoutNative",
//                .product(name: "PartoutRuntime", package: "partout")
//            ],
//            path: "Sources/Empty/AppPartoutRuntime"
//        ),
//        .binaryTarget(
//            name: "PartoutNative",
//            path: "PartoutNative.xcframework"
//        ),
        .testTarget(
            name: "AppLibraryTests",
            dependencies: ["AppLibrary"]
        ),
        .testTarget(
            name: "AppLibraryMainTests",
            dependencies: ["AppLibraryMainWrapper"]
        )
    ]
)
