// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor @Observable
final class ProfileImporter {
    typealias ImportBlock = @Sendable (ABI.ProfileImporterInput, String?) async throws -> Void

    var isPresentingPassphrase = false

    var currentPassphrase = ""

    private(set) var inputsRequiringPassphrase: [ABI.ProfileImporterInput] = []

    var nextInput: ABI.ProfileImporterInput? {
        inputsRequiringPassphrase.first
    }

    @discardableResult
    func tryImport(
        inputs: [ABI.ProfileImporterInput],
        block: @escaping ImportBlock
    ) async throws -> (imported: Int, failed: Int) {
        var withPassphrase: [ABI.ProfileImporterInput] = []
        var imported = 0
        var failed = 0

        for input in inputs {
            do {
                try await importInput(
                    input,
                    withPassphrase: nil,
                    block: block
                )
                imported += 1
            } catch {
                let appError = ABI.AppError(error)
                switch appError {
                case .partout(let error) where error.isOpenVPNPassphraseRequired:
                    withPassphrase.append(input)
                    continue
                default:
                    // One bad archive entry must not abort a bulk import.
                    if case .contents = input {
                        pspLog(.profiles, .error, "Unable to import archive entry: \(error)")
                        failed += 1
                        continue
                    }
                    pspLog(.profiles, .fault, "Unable to import URL: \(error)")
                    throw appError
                }
            }
        }

        inputsRequiringPassphrase = withPassphrase
        if !inputsRequiringPassphrase.isEmpty {
            scheduleNextImport()
        }
        return (imported, failed)
    }

    func reImport(
        input: ABI.ProfileImporterInput,
        block: @escaping ImportBlock
    ) async throws {
        do {
            try await importInput(
                input,
                withPassphrase: currentPassphrase,
                block: block
            )
            inputsRequiringPassphrase.removeFirst()
            scheduleNextImport()
        } catch {
            scheduleNextImport()
            throw error
        }
    }

    func cancelImport() {
        inputsRequiringPassphrase.removeFirst()
        scheduleNextImport()
    }
}

extension ABI.ProfileImporterInput {
    var displayName: String {
        switch self {
        case .file(let url): return url.lastPathComponent
        case .contents(let filename, _): return filename
        }
    }
}

private extension ProfileImporter {
    func scheduleNextImport() {
        guard !inputsRequiringPassphrase.isEmpty else {
            return
        }
        Task {
            // XXX: re-present same alert after artificial delay
            try? await Task.sleep(for: .milliseconds(500))
            currentPassphrase = ""
            isPresentingPassphrase = true
        }
    }

    func importInput(
        _ input: ABI.ProfileImporterInput,
        withPassphrase passphrase: String?,
        block: @escaping ImportBlock
    ) async throws {
        guard case .file(let url) = input else {
            try await block(input, passphrase)
            return
        }
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        try await block(input, passphrase)
    }
}
