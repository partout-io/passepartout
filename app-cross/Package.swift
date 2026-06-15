// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let wxWidgetsVersion = "3.3"

let package = Package(
    name: "app-cross",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../partout")
    ],
    targets: [
        .target(
            name: "passepartout-shared",
            path: "shared",
            resources: [.copy("assets")]
        ),
        .executableTarget(
            name: "passepartout",
            dependencies: [
                "partout",
                "passepartout-shared"
            ],
            path: "app",
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
                "partout",
                "passepartout-shared"
            ],
            path: "tunnel",
            cSettings: [.define("USE_SWIFTPM")]
        )
    ]
)
