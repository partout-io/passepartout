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
            targets: [
                "AppABI",
                "AppABIUI"
            ]
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
//                "CommonLibrary",
                "CommonUtils"
            ],
            exclude: ["Default"]
        ),
        .target(
            name: "AppABIUI",
            dependencies: ["AppABI"]
        ),
        .target(
            name: "CommonIAP",
            dependencies: ["CommonUtils"]
        ),
        .target(
            name: "CommonLibrary",
            dependencies: [
                "CommonIAP",
                "CommonProviders",
                "CommonUtils",
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
            name: "CommonUtils"
        )
    ]
)
