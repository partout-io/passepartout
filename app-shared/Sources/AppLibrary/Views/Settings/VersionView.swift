// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

public struct VersionView<R, Icon>: View where R: Hashable, Icon: View {

    @EnvironmentObject
    private var theme: Theme

    @Environment(\.colorScheme)
    private var colorScheme

    private let changelogRoute: R?

    private let icon: () -> Icon

    public init(changelogRoute: R? = nil as String?, icon: @escaping () -> Icon) {
        self.changelogRoute = changelogRoute
        self.icon = icon
    }

    public var body: some View {
        ScrollView {
            contentView
        }
#if os(iOS)
        .background(theme.backgroundColor(colorScheme))
        .foregroundStyle(.white)
#endif
    }
}

extension VersionView where Icon == ThemeLogo {
    public init(changelogRoute: R? = nil as String?) {
        self.init(changelogRoute: changelogRoute) {
            ThemeLogo()
        }
    }
}

private extension VersionView {
    var contentView: some View {
        Group {
            icon()
                .padding(.top)
            Spacer()
            Text(title)
                .font(.largeTitle)
            Spacer()
            Text(subtitle)
            VStack {
                Text(message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .multilineTextAlignment(.center)
                    .padding()

                if let changelogRoute {
                    NavigationLink(Strings.Unlocalized.changelog, value: changelogRoute)
                        .buttonStyle(.bordered)
                }
            }
        }
    }
}

private extension VersionView {
    var title: String {
        Strings.Unlocalized.appName
    }

    var subtitle: String {
        BundleConfiguration.mainVersionString
    }

    var message: String {
        Strings.Views.Version.extra(Strings.Unlocalized.appName, Strings.Unlocalized.authorName)
    }
}

#Preview {
    VersionView {
        ThemeImage(.cloudOn)
            .font(.largeTitle)
    }
    .withMockEnvironment()
}
