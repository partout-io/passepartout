// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI
import WebKit

public struct WebView<Coordinator> {
    private let make: () -> Coordinator

    private let update: (WKWebView, Coordinator) -> Void

    public init(
        make: @escaping () -> Coordinator,
        update: @escaping (WKWebView, Coordinator) -> Void
    ) {
        self.make = make
        self.update = update
    }
}

#if os(iOS)

extension WebView: UIViewRepresentable {
    public func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    public func makeCoordinator() -> Coordinator {
        make()
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        update(uiView, context.coordinator)
    }
}

#else

extension WebView: NSViewRepresentable {
    public func makeNSView(context: Context) -> WKWebView {
        WKWebView()
    }

    public func makeCoordinator() -> Coordinator {
        make()
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        update(nsView, context.coordinator)
    }
}

#endif

#endif
