// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

#if !os(tvOS)

public struct PinActiveProfileToggle: View {

    @AppStorage(UIPreference.pinsActiveProfile.key)
    private var pinsActiveProfile = true

    public init() {
    }

    public var body: some View {
        Toggle(Strings.Views.Preferences.pinsActiveProfile, isOn: $pinsActiveProfile.animation())
    }
}

public struct HideActiveProfileButton: View {

    @AppStorage(UIPreference.pinsActiveProfile.key)
    private var pinsActiveProfile = true

    public init() {
    }

    public var body: some View {
        Button {
            withAnimation {
                pinsActiveProfile = false
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
