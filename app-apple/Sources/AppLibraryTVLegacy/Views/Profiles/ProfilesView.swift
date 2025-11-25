// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfilesView: View {

    @EnvironmentObject
    private var configManager: ConfigManager

    @ObservedObject
    var profileManager: ProfileManager

    @ObservedObject
    var webReceiverManager: WebReceiverManager

    let registry: Registry

    @FocusState
    private var detail: Detail?

    @State
    private var errorHandler: ErrorHandler = .default()

    var body: some View {
        HStack {
            masterView
            detailView
        }
        .themeGradient()
        .withErrorHandler(errorHandler)
    }
}

private extension ProfilesView {
    var masterView: some View {
        List {
            importSection
            if profileManager.hasProfiles {
                profilesSection
            }
        }
        .themeList()
        .frame(maxWidth: .infinity)
    }

    var detailView: some View {
        DetailView(
            detail: detail,
            webReceiverManager: webReceiverManager,
            registry: registry,
            profileManager: profileManager,
            errorHandler: errorHandler
        )
        .frame(maxWidth: .infinity)
    }

    var importSection: some View {
        webReceiverButton
            .themeSection(header: Strings.Global.Actions.import)
    }

    var webReceiverButton: some View {
        Toggle(Strings.Views.Tv.Profiles.importLocal, isOn: isImporterEnabled)
            .focused($detail, equals: .import)
    }

    var profilesSection: some View {
        ForEach(profileManager.previews, id: \.id, content: row(forProfilePreview:))
            .themeSection(header: Strings.Global.Nouns.profiles)
    }

    func row(forProfilePreview preview: ABI.ProfilePreview) -> some View {
        Button {
            //
        } label: {
            HStack {
                Text(preview.name)
                Spacer()
                ProfileSharingView(
                    profileManager: profileManager,
                    profileId: preview.id
                )
            }
        }
        .contextMenu {
            Button(Strings.Global.Actions.delete, role: .destructive) {
                deleteProfile(withId: preview.id)
            }
        }
        .focused($detail, equals: .profiles)
    }
}

private extension ProfilesView {
    var isImporterEnabled: Binding<Bool> {
        Binding {
            webReceiverManager.isStarted
        } set: {
            if $0 {
                do {
                    try webReceiverManager.start()
                } catch {
                    pp_log_g(.App.core, .error, "Unable to start web receiver: \(error)")
                    errorHandler.handle(error)
                }
            } else {
                webReceiverManager.stop()
            }
       }
    }

    func deleteProfile(withId profileId: Profile.ID) {
        Task {
            await profileManager.remove(withId: profileId)
        }
    }
}

// MARK: - Detail

private enum Detail {
    case `import`

    case profiles
}

private struct DetailView: View {
    let detail: Detail?

    @ObservedObject
    var webReceiverManager: WebReceiverManager

    let registry: Registry

    @ObservedObject
    var profileManager: ProfileManager

    let errorHandler: ErrorHandler

    var body: some View {
        VStack {
            TopSpacer()
            switch detail {
            case .import:
                importView
            case .profiles:
                Text(Strings.Views.Tv.Profiles.Detail.profiles)
            default:
                Text("") // take space regardless
            }
            Spacer()
        }
    }
}

private extension DetailView {
    var importView: some View {
        WebReceiverView(
            webReceiverManager: webReceiverManager,
            registry: registry,
            profileManager: profileManager,
            errorHandler: errorHandler
        )
    }
}

// MARK: - Preview

#Preview("Empty") {
    ProfilesView(
        profileManager: ProfileManager(profiles: []),
        webReceiverManager: .forPreviews,
        registry: Registry()
    )
    .withMockEnvironment()
}

#Preview("Profiles") {
    ProfilesView(
        profileManager: .forPreviews,
        webReceiverManager: .forPreviews,
        registry: Registry()
    )
    .withMockEnvironment()
}
