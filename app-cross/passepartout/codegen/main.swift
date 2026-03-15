// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import Foundation
import PartoutCodegen

enum EntityTarget: String, CaseIterable {
    case abi
    case partout
}

do {
    let args = CommandLine.arguments
    guard args.count > 1 else {
        let known = EntityTarget.allCases
            .map(\.rawValue)
            .joined(separator: "|")
        fatalError("Missing entity target (\(known))")
    }
    guard args.count > 2 else {
        let known = Codegen.Output.allCases
            .map(\.rawValue)
            .joined(separator: "|")
        fatalError("Missing encoder name (\(known))")
    }
    let targetName = args[1]
    let outputType = args[2]
    let root = args.count > 3 ? args[3] : "."

    guard let target = EntityTarget(rawValue: targetName) else {
        fatalError("Unknown target '\(targetName)'")
    }
    guard let output = Codegen.Output(rawValue: outputType) else {
        fatalError("Unknown output '\(outputType)'")
    }

    // Swift sources
    let paths: [String]
    let entities: [String]
    switch target {
    case .abi:
        paths = ABICodegen.paths.map {
            "\(root)/Sources/\($0)"
        }
        entities = ABICodegen.entities
    case .partout:
        paths = PartoutCodegen.paths.map {
            "\(root)/partout/Sources/\($0)"
        }
        entities = PartoutCodegen.entities
    }

    // Configure encoder with output type
    let encoder: CodegenEncoder
    switch output {
    case .swift:
        encoder = SwiftEncoder()
    case .kotlin:
        switch target {
        case .abi:
            encoder = KotlinEncoder(
                packageName: "com.algoritmico.passepartout.abi",
                preamble: "import io.partout.abi.*\n",
                sealed: .init(
                    classes: [
                        .init(name: "ABI_Event", discriminator: "eventType")
                    ],
                    baseClass: { fqTypeName in
                        if fqTypeName.contains("Event_") { return "ABI_Event" }
                        return nil
                    }
                ),
                replacement: nil,
                skipsProperty: { name, fqTypeName in
                    guard fqTypeName == "ABI_ProfileEvent_Save" else { return false }
                    return name == "profile" || name == "previous"
                }
            )
        case .partout:
            encoder = KotlinEncoder(
                packageName: "io.partout.abi"
            )
        }
    case .cxx:
        fatalError("C++ encoder not implemented")
    }

    // Write output to stdout
    let codegen = Codegen(encoder: encoder)
    let code = try codegen.generate(from: paths, entities: entities)
    print(code)
} catch {
    print(error)
}

private enum ABICodegen {
    static let paths: [String] = [
        "CommonLibraryCore/Domain",
        "CommonProvidersCore"
    ]

    static let entities: [String] = [
        "ABI.AppFeature",
        "ABI.AppProduct",
        "ABI.AppProfileHeader",
        "ABI.AppTunnelInfo",
        "ABI.AppTunnelStatus",
        "ABI.ConfigFlag",
        "ABI.OriginalPurchase",
        "ABI.ProfileSharingFlag",
        "ABI.ProviderInfo",
        "ProviderID",
        "ABI.SemanticVersion",
        "ABI.VersionRelease",
        "ABI.WebFileUpload",
        "ABI.WebsiteWithPasscode",
        "ABI.ConfigEvent.Refresh",
        "ABI.IAPEvent.EligibleFeatures",
        "ABI.IAPEvent.LoadReceipt",
        "ABI.IAPEvent.NewReceipt",
        "ABI.IAPEvent.Status",
        "ABI.ProfileEvent.ChangeRemoteImporting",
        "ABI.ProfileEvent.LocalProfiles",
        "ABI.ProfileEvent.Ready",
        "ABI.ProfileEvent.Refresh",
        "ABI.ProfileEvent.Save",
        "ABI.ProfileEvent.StartRemoteImport",
        "ABI.ProfileEvent.StopRemoteImport",
        "ABI.TunnelEvent.Refresh",
        "ABI.VersionEvent.New",
        "ABI.WebReceiverEvent.NewUpload",
        "ABI.WebReceiverEvent.Start",
        "ABI.WebReceiverEvent.Stop",
        "ABI.WebReceiverEvent.UploadFailure"
    ]
}
