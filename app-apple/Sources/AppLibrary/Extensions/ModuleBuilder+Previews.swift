// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

extension ModuleBuilder where Self: ModuleViewProviding {

    @MainActor
    public func preview(title: String = "") -> some View {
        PreviewView(title: title, builder: self)
    }

    @MainActor
    public func preview<C: View>(with content: (Self, ProfileEditor) -> C) -> some View {
        NavigationStack {
            content(self, ProfileEditor(modules: [self]))
        }
        .withMockEnvironment()
    }
}

private struct PreviewView<Builder>: View where Builder: ModuleBuilder & ModuleViewProviding {
    let title: String

    let builder: Builder

    @State
    private var editor = ProfileEditor()

    var body: some View {
        NavigationStack {
            builder.moduleView(with: .init(
                registry: Registry(),
                editor: editor,
                impl: nil
            ))
            .navigationTitle(title)
        }
        .onLoad {
            editor.saveModule(builder, activating: true)
        }
        .withMockEnvironment()
    }
}
