// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "SharedResources",
    products: [
        .library(name: "SharedResources", targets: ["SharedResources"])
    ],
    targets: [
        .target(
            name: "SharedResources",
            path: ".",
            sources: ["SharedResources.swift"],
            resources: [
                .copy("constants.json"),
                .copy("credits.json"),
                .copy("issue.txt")
            ]
        )
    ]
)
