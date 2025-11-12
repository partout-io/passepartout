// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

import SwiftUI

extension WireGuardView {
    struct ImportModifier: ViewModifier {

        @ObservedObject
        var draft: ModuleDraft<WireGuardModule.Builder>

        let impl: WireGuardModule.Implementation?

        @Binding
        var isImporting: Bool

        @ObservedObject
        var errorHandler: ErrorHandler

        let onImport: (WireGuard.Configuration.Builder?) -> Void

        @State
        private var importURL: URL?

        func body(content: Content) -> some View {
            content
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [.item],
                    onCompletion: importConfiguration
                )
        }
    }
}

private extension WireGuardView.ImportModifier {
    func importConfiguration(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            guard url.startAccessingSecurityScopedResource() else {
                throw AppError.permissionDenied
            }
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            importURL = url

            guard let impl else {
                fatalError("Requires WireGuardModule implementation")
            }
            let parsed: Module
            do {
                parsed = try impl.importerBlock().module(fromURL: url, object: nil)
            } catch let error as PartoutError {
                pp_log_g(.App.core, .error, "Unable to parse URL: \(error)")

                switch error.code {
                case .unknownImportedModule:
                    throw PartoutError(.parsing)

                default:
                    throw error
                }
            }
            guard let module = parsed as? WireGuardModule else {
                throw PartoutError(.parsing)
            }
            draft.module.configurationBuilder = module.configuration?.builder()
            onImport(draft.module.configurationBuilder)
        } catch {
            pp_log_g(.App.core, .error, "Unable to import WireGuard configuration: \(error)")
            errorHandler.handle(error, title: draft.module.moduleType.localizedDescription)
        }
    }
}
