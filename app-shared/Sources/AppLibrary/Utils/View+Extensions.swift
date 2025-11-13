// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

extension View {
    public var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    public func debugChanges(condition: Bool = false) {
        if condition {
            Self._printChanges()
        }
    }

    @ViewBuilder
    public func `if`(_ condition: Bool) -> some View {
        if condition {
            self
        }
    }

    public func opaque(_ condition: Bool) -> some View {
        opacity(condition ? 1.0 : 0.0)
    }

    // https://www.avanderlee.com/swiftui/disable-animations-transactions/
    public func unanimated() -> some View {
        transaction {
            $0.animation = nil
        }
    }

    public func resized(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        GeometryReader { geo in
            self
                .frame(
                    width: width.map {
                        $0 * geo.size.width
                    },
                    height: height.map {
                        $0 * geo.size.height
                    }
                )
        }
    }

    public func scrollableOnTV() -> some View {
#if os(tvOS)
//        focusable()
        Button {
            //
        } label: {
            self
        }
#else
        self
#endif
    }

    public func copyToPasteboard(_ string: String) {
#if os(iOS)
        let pb: UIPasteboard = .general
        pb.string = string
#elseif os(macOS)
        let pb: NSPasteboard = .general
        pb.clearContents()
        pb.setString(string, forType: .string)
#else
        fatalError("Copy unavailable")
#endif
    }
}

extension ViewModifier {
    public func debugChanges(condition: Bool = false) {
        if condition {
            Self._printChanges()
        }
    }
}

@MainActor
public func enableLater(millis: Int = 50, block: @escaping (Bool) -> Void) {
    Task {
        block(false)
        try await Task.sleep(for: .milliseconds(millis))
        block(true)
    }
}

@MainActor
public func setLater<T>(_ value: T?, millis: Int = 50, block: @escaping (T?) -> Void) {
    Task {
        block(nil)
        try await Task.sleep(for: .milliseconds(millis))
        block(value)
    }
}

#if !os(tvOS)
extension Table {

    @ViewBuilder
    public func withoutColumnHeaders() -> some View {
        if #available(iOS 17, macOS 14, *) {
            tableColumnHeaders(.hidden)
        } else {
            self
        }
    }
}
#endif
