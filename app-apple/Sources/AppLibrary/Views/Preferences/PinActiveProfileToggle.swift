// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

#if !os(tvOS)

public struct PinActiveProfileToggle: View {
    @Environment(UserPreferencesObservable.self)
    private var userPreferences

    public init() {
    }

    public var body: some View {
        Toggle(Strings.Views.Preferences.pinsActiveProfile, isOn: userPreferences.binding(\.pinsActiveProfile).animation())
    }
}

public struct HideActiveProfileButton: View {
    @Environment(UserPreferencesObservable.self)
    private var userPreferences

    public init() {
    }

    public var body: some View {
        Button {
            withAnimation {
                userPreferences.pinsActiveProfile = false
            }
        } label: {
            ThemeImageLabel(Strings.Global.Actions.hide, .hide)
        }
    }
}

public struct HideActiveProfileModifier: ViewModifier {
    public init() {
    }

    public func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing) {
                HideActiveProfileButton()
            }
    }
}

#endif
