// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// https://stackoverflow.com/a/32238344/784615
// https://gist.github.com/lukaskubanek/cbfcab29c0c93e0e9e0a16ab09586996

public final class TestFlightChecker: BetaChecker {
    public init() {
    }

    public func isBeta() async -> Bool {
        await Task.detached {
            self.verifyBetaBuild()
        }.value
    }
}

// MARK: Shared

private extension TestFlightChecker {

    // IMPORTANT: check Mac first because os(iOS) holds true for Catalyst
    func verifyBetaBuild() -> Bool {
#if os(macOS) || targetEnvironment(macCatalyst)
        isMacTestFlightBuild
#elseif os(iOS) || os(tvOS)
        isSandboxBuild
#else
        false
#endif
    }

    var bundle: Bundle {
        .main
    }
}

// MARK: iOS/tvOS

#if os(iOS) || os(tvOS)
private extension TestFlightChecker {
    var isSandboxBuild: Bool {
        guard let url = bundle.appStoreReceiptURL else {
            NSLog("No Bundle.main.appStoreReceiptURL")
            return false
        }
        NSLog("Bundle.main.appStoreReceiptURL = \(url)")
        return bundle.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }
}
#endif

// MARK: macOS

#if os(macOS) || targetEnvironment(macCatalyst)
private extension TestFlightChecker {
    var isMacTestFlightBuild: Bool {
        var status = noErr

        var code: SecStaticCode?
        status = SecStaticCodeCreateWithPath(bundle.bundleURL as CFURL, [], &code)
        guard status == noErr else {
            return false
        }
        guard let code else {
            return false
        }

        var requirement: SecRequirement?
        status = SecRequirementCreateWithString(
            "anchor apple generic and certificate leaf[field.1.2.840.113635.100.6.1.25.1]" as CFString,
            [], // default
            &requirement
        )
        guard status == noErr else {
            return false
        }
        guard let requirement else {
            return false
        }

        status = SecStaticCodeCheckValidity(
            code,
            [], // default
            requirement
        )
        return status == errSecSuccess
    }
}
#endif
