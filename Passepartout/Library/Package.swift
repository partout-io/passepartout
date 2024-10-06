// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Library",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AppLibrary",
            targets: ["AppLibrary"]
        ),
        .library(
            name: "AppUI",
            targets: [
                "AppDataProfiles",
                "AppUI"
            ]
        ),
        .library(
            name: "TunnelLibrary",
            targets: ["CommonLibrary"]
        )
    ],
    dependencies: [
//        .package(url: "git@github.com:passepartoutvpn/passepartoutkit-source", from: "0.8.0"),
        .package(url: "git@github.com:passepartoutvpn/passepartoutkit-source", revision: "7efa18eb75b7a102781be3c62cd31a08607f03c8"),
//        .package(path: "../../../passepartoutkit-source"),
        .package(url: "git@github.com:passepartoutvpn/passepartoutkit-source-openvpn-openssl", from: "0.8.0"),
//        .package(url: "git@github.com:passepartoutvpn/passepartoutkit-source-openvpn-openssl", revision: "031863a1cd683962a7dfe68e20b91fa820a1ecce"),
//        .package(path: "../../../passepartoutkit-source-openvpn-openssl"),
        .package(url: "git@github.com:passepartoutvpn/passepartoutkit-source-wireguard-go", from: "0.8.0"),
//            .package(url: "git@github.com:passepartoutvpn/passepartoutkit-source-wireguard-go", revision: "ea39fa396e98cfd2b9a235f0a801aaf03a37e30a"),
//        .package(path: "../../../passepartoutkit-source-wireguard-go"),
        .package(url: "https://github.com/Cocoanetics/Kvitto", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AppData",
            dependencies: [
                .product(name: "PassepartoutKit", package: "passepartoutkit-source")
            ]
        ),
        .target(
            name: "AppDataProfiles",
            dependencies: [
                "AppData",
                "UtilsLibrary",
                .product(name: "PassepartoutKit", package: "passepartoutkit-source")
            ],
            resources: [
                .process("Profiles.xcdatamodeld")
            ]
        ),
        .target(
            name: "AppLibrary",
            dependencies: [
                "AppData",
                "CommonLibrary",
                "Kvitto",
                "LegacyV2",
                "UtilsLibrary"
            ]
        ),
        .target(
            name: "AppUI",
            dependencies: ["AppLibrary"],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "CommonLibrary",
            dependencies: [
                .product(name: "PassepartoutKit", package: "passepartoutkit-source"),
                .product(name: "PassepartoutOpenVPNOpenSSL", package: "passepartoutkit-source-openvpn-openssl"),
                .product(name: "PassepartoutWireGuardGo", package: "passepartoutkit-source-wireguard-go")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "LegacyV2",
            dependencies: [
                .product(name: "PassepartoutKit", package: "passepartoutkit-source")
            ],
            resources: [
                .process("Profiles.xcdatamodeld")
            ]
        ),
        .target(
            name: "UtilsLibrary"
        ),
        .testTarget(
            name: "AppLibraryTests",
            dependencies: ["AppLibrary"]
        ),
        .testTarget(
            name: "AppUITests",
            dependencies: ["AppUI"]
        )
    ]
)
