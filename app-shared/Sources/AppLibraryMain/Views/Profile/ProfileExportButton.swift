// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
import SwiftUI

struct ProfileExportButton: View {
    private struct ViewModel: Equatable {
        var jsonString: String?
        var isExporting = false
    }

    @EnvironmentObject
    private var registryCoder: RegistryCoder

    private let profile: Profile

    @State
    private var viewModel = ViewModel()

    @StateObject
    private var errorHandler: ErrorHandler = .default()

    init(profile: Profile) {
        self.profile = profile
    }

    init?(editor: ProfileEditor) {
        do {
            let profile = try editor.profile.builder().build()
            self.init(profile: profile)
        } catch {
            pp_log_g(.App.profiles, .error, "Unable to build profile from editor: \(error)")
            return nil
        }
    }

    var body: some View {
        Button(action: exportProfiles, label: exportLabel)
            .fileExporter(
                isPresented: $viewModel.isExporting,
                document: viewModel.jsonString.map(JSONFile.init(string:)),
                contentType: .json,
                defaultFilename: profile.defaultFilename,
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
            viewModel.jsonString = try profile.writeToJSON(coder: registryCoder)
            viewModel.isExporting = true
        } catch {
            errorHandler.handle(error)
        }
    }
}
