//
//  InteractiveCoordinator.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/8/24.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import CommonUtils
import PassepartoutKit
import SwiftUI

public struct InteractiveCoordinator: View {
    public enum Style {
        case modal

        case inline(withCancel: Bool)
    }

    private let style: Style

    @ObservedObject
    private var manager: InteractiveManager

    private let onError: (Error) -> Void

    public init(style: Style, manager: InteractiveManager, onError: @escaping (Error) -> Void) {
        self.style = style
        self.manager = manager
        self.onError = onError
    }

    public var body: some View {
        switch style {
        case .modal:
            interactiveView
                .modifier(ModalInteractiveModifier(
                    title: title,
                    confirm: confirm,
                    cancel: cancel
                ))

        case .inline(let withCancel):
            interactiveView
                .modifier(InlineInteractiveModifier(
                    title: title,
                    withCancel: withCancel,
                    confirm: confirm,
                    cancel: cancel
                ))
        }
    }
}

// MARK: - Modal

private extension InteractiveCoordinator {
    struct ModalInteractiveModifier: ViewModifier {
        let title: String

        let confirm: () -> Void

        let cancel: () -> Void

        func body(content: Content) -> some View {
            NavigationStack {
                Form {
                    content
                }
                .themeForm()
                .themeNavigationDetail()
                .navigationTitle(title)
                .toolbar(content: modalToolbar)
            }
        }

        @ToolbarContentBuilder
        func modalToolbar() -> some ToolbarContent {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: confirm) {
                    Text(Strings.Global.connect)
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(action: cancel) {
                    ThemeCloseLabel()
                }
            }
        }
    }
}

// MARK: - Inline

private extension InteractiveCoordinator {
    struct InlineInteractiveModifier: ViewModifier {
        let title: String

        let withCancel: Bool

        let confirm: () -> Void

        let cancel: () -> Void

        func body(content: Content) -> some View {
            VStack {
                Text(title)
                    .font(.title2)
                content
                toolbar
                    .padding(.top)
                Spacer()
            }
#if os(tvOS)
            .scrollClipDisabled()
#endif
        }

        var toolbar: some View {
            VStack {
                Button(action: confirm) {
                    Text(Strings.Global.connect)
                        .frame(maxWidth: .infinity)
                }
                if withCancel {
                    Button(role: .cancel, action: cancel) {
                        Text(Strings.Global.cancel)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Common

private extension InteractiveCoordinator {
    var interactiveView: some View {
        manager
            .editor
            .interactiveProvider
            .map(innerView)
    }

    func innerView(with provider: any InteractiveViewProviding) -> some View {
        AnyView(provider.interactiveView(with: manager.editor, onSubmit: confirm))
    }

    var title: String {
        manager.editor.profile.name
    }

    func confirm() {
        Task {
            do {
                try await manager.complete()
            } catch {
                onError(error)
            }
        }
    }

    func cancel() {
        manager.isPresented = false
    }
}

private extension ProfileEditor {

    // in the future, multiple modules may be interactive
    // here we only intercept the first interactive module
    var interactiveProvider: (any InteractiveViewProviding)? {
        modules
            .first {
                $0 is any InteractiveViewProviding
            } as? any InteractiveViewProviding
   }
}
