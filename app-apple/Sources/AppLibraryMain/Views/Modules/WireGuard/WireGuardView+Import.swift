// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension WireGuardView {
    struct ImportModifier: ViewModifier {
        @Environment(\.appImportExport)
        private var appImportExport

        @ObservedObject
        var draft: ModuleDraft<WireGuardModule.Builder>

        let impl: WireGuardModule.Implementation?

        @Binding
        var isImporting: Bool

        let errorHandler: ErrorHandler

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
                throw ABI.AppError.permissionDenied
            }
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            importURL = url

            let parsed: Module
            do {
                if appImportExport.isEnabled(.zigCodingImport) {
                    parsed = try appImportExport.importedModule(
                        from: .file(url),
                        context: .WireGuard
                    )
                } else {
                    guard let impl else {
                        fatalError("Requires WireGuardModule implementation")
                    }
                    parsed = try impl.importerBlock().module(fromURL: url, object: nil)
                }
            } catch {
                pspLog(.core, .error, "Unable to parse URL: \(error)")
                throw ABI.AppError(error)
            }
            guard let module = parsed as? WireGuardModule else {
                throw ABI.AppError.importError()
            }
            draft.module.configurationBuilder = module.configuration?.builder()
            onImport(draft.module.configurationBuilder)
        } catch {
            pspLog(.core, .error, "Unable to import WireGuard configuration: \(error)")
            errorHandler.handle(error, title: draft.module.moduleType.localizedDescription)
        }
    }
}
