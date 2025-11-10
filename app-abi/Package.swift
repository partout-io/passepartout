// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "AppABI",
            targets: ["AppABI"],
        ),
        .library(
            name: "CommonLibrary",
            targets: ["CommonLibrary"]
        )
    ],
    dependencies: [
        .package(path: "../submodules/partout")
    ],
    targets: [
        .target(
            name: "AppABI_C",
        ),
        .target(
            name: "AppABI",
            dependencies: [
                "AppABI_C",
                "CommonLibrary",
                "CommonUI",
                "CommonUtils"
            ]
        ),
        .executableTarget(
            name: "AppABIUI",
            dependencies: ["AppABI"]
        ),
        .target(
            name: "CommonLibrary",
            dependencies: [
                "CommonProviders",
                "CommonUI",
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
            name: "CommonUI",
            dependencies: [
                "AppABI_C",
                "CommonUtils"
            ]
        ),
        .target(
            name: "CommonUtils"
        )
    ]
)
