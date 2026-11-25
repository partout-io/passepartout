// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

@MainActor @Observable
public final class InteractiveObservable {
    public typealias CompletionBlock = (InteractiveLogin) throws -> Void

    public var isPresented = false

    public private(set) var editor = ProfileEditor()

    public private(set) var login: InteractiveLogin?

    private var onComplete: CompletionBlock?

    public init() {
    }

    public func present(with profile: Profile, onComplete: CompletionBlock?) {
        login = InteractiveLogin(original: profile)
        editor = ProfileEditor()
        editor.load(profile.editable(), isShared: false)
        self.onComplete = onComplete
        isPresented = true
    }

    public func complete() throws {
        isPresented = false
        let newProfile = try editor.buildAndUpdate()
        guard var login,
              let credentials = newProfile.activeModules.compactMap({ $0 as? OpenVPNModule }).first(where: { $0.id == login.moduleId })?.credentials else {
            throw ABI.AppError.interactiveLogin
        }
        login.username = credentials.username
        login.password = login.needsOTP ? credentials.otp ?? "" : credentials.password
        self.login = nil
        try onComplete?(login)
    }
}
