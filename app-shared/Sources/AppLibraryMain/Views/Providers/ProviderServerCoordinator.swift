// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProviderServerCoordinator: View {

    @Environment(\.dismiss)
    private var dismiss

    // FIXME: #1470, heavy data copy in SwiftUI
    let module: ProviderModule

    let selectTitle: String

    let onSelect: (ProviderEntity) async throws -> Void

    @ObservedObject
    var errorHandler: ErrorHandler

    var body: some View {
        ProviderServerView(
            module: module,
            selectTitle: selectTitle,
            onSelect: onSelect
        )
        .themeNavigationStack(closable: true)
    }
}

private extension ProviderServerCoordinator {
    func onSelect(entity: ProviderEntity) {
        Task {
            do {
                dismiss()
                try await onSelect(entity)
            } catch {
                pp_log_g(.App.core, .fault, "Unable to select server \(entity.server.serverId) for provider \(entity.server.metadata.providerId): \(error)")
                errorHandler.handle(error, title: Strings.Views.Providers.selectEntity)
            }
        }
    }
}
