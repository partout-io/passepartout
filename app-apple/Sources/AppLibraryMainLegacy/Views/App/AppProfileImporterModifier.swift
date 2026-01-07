// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct AppProfileImporterModifier: ViewModifier {
    let profileManager: ProfileManager

    @Binding
    var isPresented: Bool

    let errorHandler: ErrorHandler

    @State
    private var importer = AppProfileImporter()

    func body(content: Content) -> some View {
        content
            .fileImporter(
                isPresented: $isPresented,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true,
                onCompletion: handleResult
            )
            .onReceive(AppPipe.importer) {
                handleResult(.success($0))
            }
            .alert(
                Strings.Views.App.Toolbar.importFile,
                isPresented: $importer.isPresentingPassphrase,
                presenting: importer.nextURL,
                actions: actions,
                message: message
            )
    }
}

private extension AppProfileImporterModifier {

    @ViewBuilder
    func actions(for url: URL) -> some View {
        SecureField(
            Strings.Placeholders.secret,
            text: $importer.currentPassphrase
        )
        Button(Strings.Alerts.Import.Passphrase.ok) {
            Task {
                try await importer.reImport(
                    url: url,
                    profileManager: profileManager
                )
            }
        }
        Button(Strings.Global.Actions.cancel, role: .cancel) {
            importer.cancelImport()
        }
    }

    func message(for url: URL) -> some View {
        Text(Strings.Alerts.Import.Passphrase.message(url.lastPathComponent))
    }

    func handleResult(_ result: Result<[URL], Error>) {
        Task.detached {
            do {
                let urls = try result.get()
                try await importer.tryImport(
                    urls: urls,
                    profileManager: profileManager
                )
            } catch {
                await errorHandler.handle(
                    error,
                    title: Strings.Views.App.Toolbar.importFile,
                    message: Strings.Errors.App.import
                )
            }
        }
    }
}
