// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

@MainActor @Observable
public final class InteractiveObservable {
    public typealias CompletionBlock = (Profile) throws -> Void

    public var isPresented = false

    public private(set) var editor = ProfileEditor()

    private var onComplete: CompletionBlock?

    public init() {
    }

    public func present(with profile: Profile, onComplete: CompletionBlock?) {
        editor = ProfileEditor()
        editor.load(profile.editable(), isShared: false)
        self.onComplete = onComplete
        isPresented = true
    }

    public func complete() throws {
        isPresented = false
        let newProfile = try editor.buildAndUpdate()
        try onComplete?(newProfile)
    }
}
