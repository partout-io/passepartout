// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct DebugLogView<Content>: View where Content: View {
    private let fetchLines: () async -> [String]

    private let content: ([String]) -> Content

    @State
    private(set) var currentLines: [String] = []

    public var body: some View {
        content(currentLines)
            .monospaced()
            .themeEmpty(if: currentLines.isEmpty, message: Strings.Global.Nouns.noContent)
            .toolbar(content: toolbarContent)
            .task {
                currentLines = await fetchLines()
            }
    }
}

private extension DebugLogView {
    @ViewBuilder
    func toolbarContent() -> some View {
#if !os(tvOS)
        copyButton
#endif
//        if !currentLines.isEmpty {
//            shareButton
//        }
    }

    var copyButton: some View {
        Button {
            copyToPasteboard(currentLines.joined(separator: "\n"))
        } label: {
            ThemeImage(.copy)
        }
        .disabled(currentLines.isEmpty)
    }

    // TODO: #658, share as temporary URL (could enable email)
//    var shareButton: some View {
//        ShareLink(item: content)
//    }
}

// MARK: - Shortcuts

extension DebugLogView {
    public init(
        withAppParameters parameters: ABI.Constants.Log,
        content: @escaping ([String]) -> Content
    ) {
        self.init {
            pspLogCurrent(parameters)
        } content: {
            content($0)
        }
    }

    public init(
        withTunnel tunnel: TunnelObservable,
        content: @escaping ([String]) -> Content
    ) {
        self.init {
            await tunnel.currentLog()
        } content: {
            content($0)
        }
    }

    public init(
        withURL url: URL,
        content: @escaping ([String]) -> Content
    ) {
        self.init {
            do {
                return try String(contentsOf: url)
                    .split(separator: "\n")
                    .map(String.init)
            } catch {
                return []
            }
        } content: {
            content($0)
        }
    }
}
