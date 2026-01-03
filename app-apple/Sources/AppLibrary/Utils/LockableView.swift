// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

public struct LockableView<Content: View, LockedContent: View>: View {

    @Environment(\.scenePhase)
    private var scenePhase

    // unobserved here, observed in LockedContentWrapper
    private let lock: Lock

    private let locksInBackground: Bool

    private let content: () -> Content

    private let lockedContent: () -> LockedContent

    private let unlockBlock: () async -> Bool

    @MainActor
    public init(
        locksInBackground: Bool,
        content: @escaping () -> Content,
        lockedContent: @escaping () -> LockedContent,
        unlockBlock: @escaping () async -> Bool
    ) {
        lock = .shared
        self.locksInBackground = locksInBackground
        self.content = content
        self.lockedContent = lockedContent
        self.unlockBlock = unlockBlock
    }

    public var body: some View {
        debugChanges()
        return ZStack {
            content()
            if locksInBackground {
                LockedContentWrapperView(
                    lock: lock,
                    content: lockedContent
                )
            }
        }
        .onChange(of: scenePhase, perform: onScenePhase)
    }
}

// MARK: -

@MainActor @Observable
private final class Lock {
    enum State {
        case none

        case covered

        case locked
    }

    static let shared = Lock()

    var state: State = .locked

    private init() {
    }
}

// MARK: -

@MainActor
private extension LockableView {
    func onScenePhase(_ scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            unlockIfNeeded()

        case .inactive:
            if lock.state == .none {
                lock.state = .covered
            }

        case .background:
            lockIfNeeded()

        default:
            break
        }
    }

    func lockIfNeeded() {
        guard locksInBackground else {
            return
        }
        lock.state = .locked
    }

    func unlockIfNeeded() {
        guard locksInBackground else {
            lock.state = .none
            return
        }
        switch lock.state {
        case .none:
            break

        case .covered:
            lock.state = .none

        case .locked:
            Task {
                guard await unlockBlock() else {
                    return
                }
                lock.state = .none
            }
        }
    }
}

// MARK: -

private struct LockedContentWrapperView<Content>: View where Content: View {
    let lock: Lock

    @ViewBuilder
    let content: Content

    var body: some View {
        if lock.state != .none {
            content
        }
    }
}

#endif
