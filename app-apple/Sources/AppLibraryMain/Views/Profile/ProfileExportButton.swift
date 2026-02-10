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

    @Environment(AppEncoderObservable.self)
    private var appEncoder

    @Environment(IAPObservable.self)
    private var iapObservable

    private let profile: Profile

    @State
    private var viewModel = ViewModel()

    @State
    private var errorHandler: ErrorHandler = .default()

    init(profile: Profile) {
        self.profile = profile
    }

    init?(editor: ProfileEditor) {
        do {
            let profile = try editor.profile.builder().build()
            self.init(profile: profile)
        } catch {
            pspLog(.profiles, .error, "Unable to build profile from editor: \(error)")
            return nil
        }
    }

    var body: some View {
        Button(action: exportProfiles, label: exportLabel)
            .disabled(!iapObservable.isEligible(for: .sharing))
            .fileExporter(
                isPresented: $viewModel.isExporting,
                document: viewModel.jsonString.map(JSONFile.init(string:)),
                contentType: .json,
                defaultFilename: appEncoder.defaultFilename(for: profile),
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
#endif
    }

    func exportProfiles() {
        do {
            viewModel.jsonString = try appEncoder.json(fromProfile: profile)
            viewModel.isExporting = true
        } catch {
            errorHandler.handle(error)
        }
    }
}
