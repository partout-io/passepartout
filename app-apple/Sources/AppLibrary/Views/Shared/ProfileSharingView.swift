// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

public struct ProfileSharingView: View {
    private let flags: [ABI.ProfileSharingFlag]

    private let isRemoteImportingEnabled: Bool

    public init(flags: [ABI.ProfileSharingFlag], isRemoteImportingEnabled: Bool) {
        self.flags = flags
        self.isRemoteImportingEnabled = isRemoteImportingEnabled
    }

    @available(*, deprecated, message: "#1594")
    public init(profileManager: ProfileManager, profileId: Profile.ID) {
        self.init(
            flags: profileManager.sharingFlags(for: profileId),
            isRemoteImportingEnabled: profileManager.isRemoteImportingEnabled
        )
    }

    public var body: some View {
        if !flags.isEmpty {
            ZStack(alignment: .centerFirstTextBaseline) {
                Group {
                    ThemeImage(.cloudOn)
                    ThemeImage(.cloudOff)
                    ThemeImage(.tvOn)
                    ThemeImage(.tvOff)
                }
                .hidden()

                HStack(alignment: .firstTextBaseline) {
                    ForEach(imageModels, id: \.name) {
                        ThemeImage($0.name)
                            .help($0.help)
                    }
                }
            }
            .foregroundStyle(.secondary)
        }
    }
}

private extension ProfileSharingView {
    var imageModels: [(name: Theme.ImageName, help: String)] {
        flags.compactMap {
            switch $0 {
            case .disabled:
                return nil
            case .shared:
                return (
                    isRemoteImportingEnabled ? .cloudOn : .cloudOff,
                    Strings.Unlocalized.iCloud
                )
            case .tv:
                return (
                    isRemoteImportingEnabled ? .tvOn : .tvOff,
                    Strings.Unlocalized.appleTV
                )
            }
        }
    }
}

#Preview {
    struct ContentView: View {

        @State
        private var isRemoteImportingEnabled = false

        let timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()

        var body: some View {
            ProfileSharingView(
                flags: [.shared, .tv],
                isRemoteImportingEnabled: isRemoteImportingEnabled
            )
            .onReceive(timer) { _ in
                isRemoteImportingEnabled.toggle()
            }
            .border(.black)
            .padding()
            .withMockEnvironment()
        }
    }

    return ContentView()
}

#Preview("Row Alignment") {
    IconsPreview()
        .withMockEnvironment()
}

private struct IconsPreview: View {
    var body: some View {
        Form {
            HStack(alignment: .firstTextBaseline) {
                ThemeImage(.cloudOn)
                ThemeImage(.cloudOff)
                ThemeImage(.tvOn)
                ThemeImage(.tvOff)
                ThemeImage(.info)
            }
        }
        .themeForm()
    }
}
