// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct SendToTVCoordinator: View {

    @Environment(ViewLogger.self)
    private var logger

    @Environment(AppEncoderObservable.self)
    private var appEncoder

    @Environment(\.appConfiguration)
    private var appConfiguration

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
            logger: logger,
            strategy: URLSessionUploaderStrategy(
                timeout: appConfiguration.constants.api.timeoutInterval
            )
        )
        do {
            let encodedProfile = try appEncoder.json(fromProfile: ABI.AppProfile(native: profile))
            try await client.send(
                encodedProfile,
                filename: profile.name,
                to: url,
                passcode: passcode
            )
            isPresented = false
        } catch {
            pp_log_g(.App.core, .error, "Unable to upload profile: \(error)")
            throw error
        }
    }
}
