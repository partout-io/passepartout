// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileExportButton: View {
    private struct ViewModel: Equatable {
        var jsonString: String?
        var isExporting = false
    }

    @Environment(\.appImportExport)
    private var appImportExport

    @Environment(IAPObservable.self)
    private var iapObservable

    private let profile: Profile?

    @State
    private var viewModel = ViewModel()

    @State
    private var errorHandler: ErrorHandler = .default()

    init(profile: Profile?) {
        self.profile = profile
    }

    init(editor: ProfileEditor) {
        do {
            let profile = try editor.profile.builder().build()
            self.init(profile: profile)
        } catch {
            pspLog(.profiles, .debug, "Unable to build profile from editor: \(error)")
            self.init(profile: nil)
        }
    }

    var body: some View {
        Button(action: exportProfiles, label: exportLabel)
            .disabled(profile == nil || !iapObservable.isEligible(for: .sharing))
            .fileExporter(
                isPresented: $viewModel.isExporting,
                document: viewModel.jsonString.map(TextFile.init),
                contentType: .json,
                defaultFilename: profile.map { appImportExport.defaultFilename(for: $0) },
                onCompletion: { _ in }
            )
            .withErrorHandler(errorHandler)
    }
}

private extension ProfileExportButton {
    func exportLabel() -> some View {
#if os(iOS)
        Text(Strings.Views.Profile.Buttons.export)
#else
        Text(Strings.Global.Actions.export.withTrailingDots)
            .themeToolbarLabel()
#endif
    }

    func exportProfiles() {
        guard let profile else {
            return
        }
        do {
            viewModel.jsonString = try appImportExport.json(fromProfile: profile)
            viewModel.isExporting = true
        } catch {
            errorHandler.handle(error)
        }
    }
}
