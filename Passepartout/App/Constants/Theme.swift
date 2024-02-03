//
//  Theme.swift
//  Passepartout
//
//  Created by Davide De Rosa on 2/24/22.
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

#if !os(tvOS)
import LocalAuthentication
#endif
import PassepartoutLibrary
import SwiftUI

extension View {
    var themeIdiom: UIUserInterfaceIdiom {
        UIDevice.current.userInterfaceIdiom
    }

    var themeIsiPadPortrait: Bool {
        #if !os(tvOS)
        #if targetEnvironment(macCatalyst)
        false
        #else
        let device: UIDevice = .current
        return device.userInterfaceIdiom == .pad && device.orientation.isPortrait
        #endif
        #else
        false
        #endif
    }

    var themeIsiPadMultitasking: Bool {
        #if !os(tvOS)
        #if targetEnvironment(macCatalyst)
        false
        #else
        UIDevice.current.userInterfaceIdiom == .pad
        #endif
        #else
        false
        #endif
    }
}

// MARK: Global

extension View {
    func themeGlobal() -> some View {
        themeNavigationViewStyle()
            #if !os(tvOS)
            #if !targetEnvironment(macCatalyst)
            .themeLockScreen()
            #endif
            .themeTint()
            .listStyle(themeListStyleValue())
            .toggleStyle(themeToggleStyleValue())
            .menuStyle(.borderlessButton)
            #endif
            .withErrorHandler()
    }

    #if os(tvOS)
    func themeTV() -> some View {
        GeometryReader { geo in
            self
                .padding(.horizontal, 0.25 * geo.size.width)
                .scrollClipDisabled()
        }
    }
    #endif

    func themePrimaryView() -> some View {
        #if targetEnvironment(macCatalyst)
        navigationBarTitleDisplayMode(.inline)
            .themeSidebarListStyle()
        #elseif !os(tvOS)
        navigationBarTitleDisplayMode(.large)
            .navigationTitle(Unlocalized.appName)
            .themeSidebarListStyle()
        #else
        self
        #endif
    }

    func themeSecondaryView() -> some View {
        #if !os(tvOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    private func themeNavigationViewStyle() -> some View {
        switch themeIdiom {
        case .phone:
            navigationViewStyle(.stack)

        default:
            navigationViewStyle(.automatic)
        }
    }

    @ViewBuilder
    private func themeSidebarListStyle() -> some View {
        #if !os(tvOS)
        switch themeIdiom {
        case .phone:
            listStyle(.insetGrouped)

        default:
            listStyle(.sidebar)
        }
        #else
        self
        #endif
    }

    func themeTint() -> some View {
        tint(.accentColor)
    }

    func themeListSelectionColor(isSelected: Bool) -> some View {
        let background = isSelected ? Color.gray.opacity(0.6) : .clear
        return listRowBackground(background.themeRounded())
    }

    private func themeListStyleValue() -> some ListStyle {
        #if !os(tvOS)
        .insetGrouped
        #else
        PlainListStyle()
        #endif
    }

    private func themeToggleStyleValue() -> some ToggleStyle {
        #if !os(tvOS)
        .switch
        #else
        DefaultToggleStyle()
        #endif
    }
}

// MARK: Colors

extension View {
    fileprivate var themePrimaryBackgroundColor: Color {
        Color(.primary)
    }

    fileprivate var themeSecondaryColor: Color {
        .secondary
    }

    fileprivate var themeLightTextColor: Color {
        Color(.lightText)
    }

    fileprivate var themeErrorColor: Color {
        .red
    }

    private func themeColor(_ string: String?, validator: (String) throws -> Void) -> Color? {
        guard let string = string else {
            return nil
        }
        do {
            try validator(string)
            return nil
        } catch {
            return themeErrorColor
        }
    }
}

// MARK: Images

extension View {
    var themeAssetsLogoImage: String {
        "Logo"
    }

    var themeCheckmarkImage: String {
        "checkmark"
    }

    var themeShareImage: String {
        "square.and.arrow.up"
    }

    var themeCopyImage: String {
        "doc.on.doc"
    }

    var themeCloseImage: String {
        "xmark"
    }

    var themeConceilImage: String {
        "eye.slash"
    }

    var themeRevealImage: String {
        "eye"
    }

    var themeAppleTVImage: String {
        "tv"
    }

    // MARK: Organizer

    func themeAssetsProviderImage(_ providerName: ProviderName) -> String {
        "providers/\(providerName)"
    }

    func themeAssetsCountryImage(_ countryCode: String) -> String {
        "flags/\(countryCode.lowercased())"
    }

    var themeProviderImage: String {
        "externaldrive.connected.to.line.below"
    }

    var themeHostFilesImage: String {
        "folder"
    }

    var themeHostTextImage: String {
        "text.justify"
    }

    var themeSettingsImage: String {
        "gearshape"
    }

    var themeDonateImage: String {
        "giftcard"
    }

    var themeRedditImage: String {
        "person.3"
    }

    var themeWriteReviewImage: String {
        "star"
    }

    var themeAddMenuImage: String {
        "plus"
    }

    var themeProfileActiveImage: String {
        "checkmark.circle"
    }

    var themeProfileConnectedImage: String {
        "circle.fill"
    }

    var themeProfileInactiveImage: String {
        "circle"
    }

    // MARK: Profile

    var themeSettingsMenuImage: String {
        "ellipsis.circle"
    }

    var themeReconnectImage: String {
        "arrow.clockwise"
    }

    var themeShortcutsImage: String {
        "mic"
    }

    var themeRenameProfileImage: String {
        "highlighter"
//        "character.cursor.ibeam"
    }

    var themeDuplicateImage: String {
        "doc.on.doc"
    }

    var themeUninstallImage: String {
        "arrow.uturn.down"
    }

    var themeDeleteImage: String {
        "trash"
    }

    var themeVPNProtocolImage: String {
        "bolt"
//        "waveform.path.ecg"
//        "message.and.waveform.fill"
//        "pc"
//        "captions.bubble.fill"
    }

    var themeEndpointImage: String {
        "link"
    }

    var themeAccountImage: String {
        "person"
    }

    var themeProviderLocationImage: String {
        "location"
    }

    var themeProviderPresetImage: String {
        "slider.horizontal.3"
    }

    var themeNetworkSettingsImage: String {
//        "network"
        "globe"
    }

    var themeOnDemandImage: String {
        "wifi"
    }

    var themeDiagnosticsImage: String {
        "bandage.fill"
    }

    var themeFAQImage: String {
        "questionmark.diamond"
    }

    func themeFavoritesImage(_ active: Bool) -> String {
        active ? "bookmark.fill" : "bookmark"
    }

    func themeFavoriteActionImage(_ doFavorite: Bool) -> String {
        doFavorite ? "bookmark" : "bookmark.slash.fill"
    }
}

extension String {
    var asAssetImage: Image {
        Image(self)
    }

    var asSystemImage: Image {
        Image(systemName: self)
    }
}

// MARK: Styles

extension View {
    func themeAccentForegroundStyle() -> some View {
        foregroundColor(.accentColor)
    }

    var themePrimaryBackground: some View {
        themePrimaryBackgroundColor
            .ignoresSafeArea()
    }

    func themeSecondaryTextStyle() -> some View {
        foregroundColor(themeSecondaryColor)
    }

    func themeLightTextStyle() -> some View {
        foregroundColor(themeLightTextColor)
    }

    func themePrimaryTintStyle() -> some View {
        tint(themePrimaryBackgroundColor)
    }

    func themeDestructiveTintStyle() -> some View {
        tint(themeErrorColor)
    }

    func themeTextButtonStyle() -> some View {
        accentColor(.primary)
    }

    func themeLongTextStyle() -> some View {
        lineLimit(1)
            .truncationMode(.middle)
    }

    func themeRawTextStyle() -> some View {
        disableAutocorrection(true)
            .autocapitalization(.none)
    }

    func themeInformativeTextStyle() -> some View {
        multilineTextAlignment(.center)
            .font(.title)
            .foregroundColor(themeSecondaryColor)
    }

    func themeCellTitleStyle() -> some View {
        font(.headline)
    }

    func themeCellSubtitleStyle() -> some View {
        font(.subheadline)
    }

    func themeDebugLogStyle() -> some View {
        font(.system(size: 13, weight: .medium, design: .monospaced))
    }

    func themeRounded() -> some View {
        clipShape(.rect(cornerRadius: 10.0))
    }
}

// MARK: Shortcuts

#if !os(tvOS)
extension ShortcutType {
    var themeImageName: String {
        switch self {
        case .enableVPN:
            return "power"

        case .disableVPN:
            return "xmark"

        case .reconnectVPN:
            return "arrow.clockwise"
        }
    }
}
#endif

// MARK: Animations

extension View {
    func themeAnimation<V: Equatable>(on value: V) -> some View {
        animation(.default, value: value)
    }
}

extension Binding {
    func themeAnimation() -> Binding<Value> {
        animation(.default)
    }
}

// MARK: Shortcuts

extension View {
    func themeCloseItem(presentationMode: Binding<PresentationMode>) -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                themeCloseImage.asSystemImage
            }
        }
    }

    func themeCloseItem(isPresented: Binding<Bool>) -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                isPresented.wrappedValue = false
            } label: {
                themeCloseImage.asSystemImage
            }
        }
    }

    func themeSaveButtonLabel() -> some View {
        Text(L10n.Global.Strings.save)
    }

    func themeSecureField(_ placeholder: String, text: Binding<String>, contentType: UITextContentType = .password) -> some View {
        RevealingSecureField(placeholder, text: text) {
            themeConceilImage.asSystemImage
                .themeAccentForegroundStyle()
        } revealImage: {
            themeRevealImage.asSystemImage
                .themeAccentForegroundStyle()
        }.textContentType(contentType)
        .themeRawTextStyle()
    }

    func themeTextPicker<T: Hashable>(_ title: String, selection: Binding<T>, values: [T], description: @escaping (T) -> String) -> some View {
        StyledPicker(title: title, selection: selection, values: values) {
            Text(description($0))
        } selectionLabel: {
            Text(description($0))
                .foregroundColor(themeSecondaryColor)
        } listStyle: {
            themeListStyleValue()
        }
    }

    func themeLongContentLinkDefault(_ title: String, content: Binding<String>) -> some View {
        LongContentLink(title, content: content) {
            Text($0)
                .foregroundColor(themeSecondaryColor)
        }
    }

    func themeLongContentLink(_ title: String, content: Binding<String>, withPreview preview: String? = nil) -> some View {
        LongContentLink(title, content: content, preview: preview) {
            Text(preview != nil ? $0 : "")
                .foregroundColor(themeSecondaryColor)
        }
    }

    @ViewBuilder
    func themeErrorMessage(_ message: String?) -> some View {
        if let message = message {
            if message.last != "." {
                Text("\(message).")
                    .foregroundColor(themeErrorColor)
            } else {
                Text(message)
                    .foregroundColor(themeErrorColor)
            }
        } else {
            EmptyView()
        }
    }
}

// MARK: Lock screen

#if !os(tvOS)
extension View {
    func themeLockScreen() -> some View {
        @AppStorage(AppPreference.locksInBackground.key) var locksInBackground = false
        return LockableView(
            locksInBackground: $locksInBackground,
            content: {
                self
            },
            lockedContent: LogoView.init,
            unlockBlock: Self.themeUnlockScreenBlock
        )
    }

    private static func themeUnlockScreenBlock() async -> Bool {
        let context = LAContext()
        let policy: LAPolicy = .deviceOwnerAuthentication
        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else {
            return true
        }
        do {
            let isAuthorized = try await context.evaluatePolicy(
                policy,
                localizedReason: L10n.Global.Messages.unlockApp
            )
            return isAuthorized
        } catch {
            return false
        }
    }
}
#endif

// MARK: Validation

extension View {
    func themeValidProfileName() -> some View {
        themeRawTextStyle()
    }

    func themeValidURL(_ urlString: String?) -> some View {
        themeValidating(urlString, validator: Validators.url)
            .keyboardType(.asciiCapable)
            .themeRawTextStyle()
    }

    func themeValidIPAddress(_ ipAddress: String?) -> some View {
        themeValidating(ipAddress, validator: Validators.ipAddress)
            .keyboardType(.numbersAndPunctuation)
            .themeRawTextStyle()
    }

    func themeValidSocketPort(_ port: String?) -> some View {
        themeValidating(port, validator: Validators.socketPort)
            .keyboardType(.numberPad)
    }

    func themeValidDomainName(_ domainName: String?) -> some View {
        themeValidating(domainName, validator: Validators.domainName)
            .keyboardType(.asciiCapable)
            .themeRawTextStyle()
    }

    func themeValidWildcardDomainName(_ domainName: String?) -> some View {
        themeValidating(domainName, validator: Validators.wildcardDomainName)
            .keyboardType(.asciiCapable)
            .themeRawTextStyle()
    }

    func themeValidDNSOverTLSServerName(_ string: String?) -> some View {
        themeValidating(string, validator: Validators.dnsOverTLSServerName)
            .keyboardType(.asciiCapable)
            .themeRawTextStyle()
    }

    func themeValidSSID(_ text: String?) -> some View {
        themeValidating(text, validator: Validators.notEmpty)
            .keyboardType(.asciiCapable)
            .themeRawTextStyle()
    }

    private func themeValidating(_ string: String?, validator: (String) throws -> Void) -> some View {
        foregroundColor(themeColor(string, validator: validator))
    }
}

// MARK: Hacks

extension View {
    @available(*, deprecated, message: "Mitigates multiline text truncation (1.0 does not work though)")
    func xxxThemeTruncation() -> some View {
        minimumScaleFactor(0.5)
    }
}
