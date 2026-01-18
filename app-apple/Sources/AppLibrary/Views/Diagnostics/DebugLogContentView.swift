// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct DebugLogContentView: View {

    @Environment(Theme.self)
    private var theme

    public let lines: [String]

    public init(lines: [String]) {
        self.lines = lines
    }

    public var body: some View {
        ScrollViewReader { proxy in
            scrollView
                .onLoad {
                    withAnimation {
                        proxy.scrollTo(lines.count - 1, anchor: .bottom)
                    }
                }
        }
    }
}

#if os(macOS)

private extension DebugLogContentView {
    struct Entry: Identifiable {
        let id: Int

        let line: String
    }

    var scrollView: some View {
        let entries = lines
            .enumerated()
            .map {
                Entry.init(id: $0.offset, line: $0.element)
            }

        return Table(entries) {
            TableColumn("") { entry in
                HStack {
                    EmptyView()
                        .themeTip(entry.line, edge: .bottom, width: 400.0, alignment: .leading) {
                            ThemeImage(.search)
                        }
                        .environment(theme) // TODO: #873, Table loses environment

                    Text(entry.line)
                        .font(.caption)
                }
            }
        }
        .withoutColumnHeaders()
    }
}

#else

private extension DebugLogContentView {
    var scrollView: some View {
        List(lines.indices, id: \.self, rowContent: entryView)
            .listStyle(.plain)
    }

    func entryView(for index: Int) -> some View {
        Text(lines[index])
            .themeMultiLine(true)
            .scrollableOnTV()
            .buttonStyle(.plain)
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(index)
    }
}

#endif

#Preview {
    DebugLogContentView(
        lines: Array(repeating: "foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar foobar ", count: 200)
    )
    .withMockEnvironment()
}
