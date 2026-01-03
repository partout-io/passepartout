// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout

@MainActor @Observable
public final class InteractiveObservable {
    public typealias CompletionBlock = (ABI.AppProfile) throws -> Void

    public var isPresented = false

    public private(set) var editor = ProfileEditor()

    private var onComplete: CompletionBlock?

    public init() {
    }

    public func present(with profile: ABI.AppProfile, onComplete: CompletionBlock?) {
        editor = ProfileEditor()
        editor.load(profile.native.editable(), isShared: false)
        self.onComplete = onComplete
        isPresented = true
    }

    public func complete() throws {
        isPresented = false
        let newProfile = try editor.buildAndUpdate()
        try onComplete?(ABI.AppProfile(native: newProfile))
    }
}
