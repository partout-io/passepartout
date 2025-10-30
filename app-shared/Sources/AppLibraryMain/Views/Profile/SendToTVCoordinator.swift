// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
import SwiftUI

struct SendToTVCoordinator: View {

    @EnvironmentObject
    private var registryCoder: RegistryCoder

    let profile: Profile

    @Binding
    var isPresented: Bool

    var body: some View {
        SendToTVView(isPresented: $isPresented) {
            try await upload(profile, to: $0, with: $1)
        }
        .task {
            LocalNetworkPermissionService().request()
        }
    }
}

private extension SendToTVCoordinator {
    func upload(_ profile: Profile, to url: URL, with passcode: String) async throws {
        let client = WebUploader(
            registryCoder: registryCoder,
            strategy: URLSessionUploaderStrategy(
                timeout: Constants.shared.api.timeoutInterval
            )
        )
        do {
            try await client.send(profile, to: url, passcode: passcode)
            isPresented = false
        } catch {
            pp_log_g(.App.core, .error, "Unable to upload profile: \(error)")
            throw error
        }
    }
}
