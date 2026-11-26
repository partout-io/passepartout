// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

/// Input for one connection attempt, separate from the saved profile.
public struct InteractiveLogin: Sendable {
    public let original: Profile
    public let moduleId: UniqueID?
    public let needsOTP: Bool
    public var username: String
    /// The raw OTP when needsOTP is true, otherwise the password.
    public var password: String

    public init(original: Profile) {
        self.original = original
        let module = original.activeModules
            .compactMap { $0 as? OpenVPNModule }
            .first(where: \.isInteractive)
        moduleId = module?.id
        let credentials = module?.credentials
        needsOTP = credentials.map { $0.otpMethod != .none } ?? false
        username = credentials?.username ?? ""
        password = ""
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
