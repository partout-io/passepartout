// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

/// Input for one connection attempt, separate from the saved profile.
public struct InteractiveLogin: Sendable {
    public let original: Profile
    public var username: String
    /// The raw OTP when needsOTP is true, otherwise the password.
    public var password: String
    public let needsOTP: Bool
    public let moduleId: UniqueID?

    public init(original: Profile) {
        self.original = original
        let module = original.activeModules.compactMap { $0 as? OpenVPNModule }.first { $0.isInteractive }
        moduleId = module?.id
        let credentials = module?.credentials
        username = credentials?.username ?? ""
        needsOTP = credentials.map { $0.otpMethod != .none } ?? false
        password = needsOTP ? "" : credentials?.password ?? ""
    }

    public func connectionProfile() throws -> Profile {
        guard moduleId != nil else { throw ABI.AppError.interactiveLogin }
        return try original.withInteractiveLogin(
            username: username,
            password: password,
            otp: needsOTP ? password : nil
        )
    }
}
