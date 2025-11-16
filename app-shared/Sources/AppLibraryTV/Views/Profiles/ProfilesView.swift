// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfilesView: View {

    @Environment(ViewLogger.self)
    private var logger

    @EnvironmentObject
    private var configManager: ConfigManager

    let profileObservable: ProfileObservable

    @ObservedObject
    var webReceiverManager: WebReceiverManager

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
            if profileObservable.hasProfiles {
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
            profileObservable: profileObservable,
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
        ForEach(profileObservable.filteredHeaders, id: \.id, content: row(forHeader:))
            .themeSection(header: Strings.Global.Nouns.profiles)
    }

    func row(forHeader header: ABI.AppProfileHeader) -> some View {
        Button {
            //
        } label: {
            HStack {
                Text(header.name)
                Spacer()
                ProfileSharingView(
                    flags: header.sharingFlags,
                    isRemoteImportingEnabled: profileObservable.isRemoteImportingEnabled
                )
            }
        }
        .contextMenu {
            Button(Strings.Global.Actions.delete, role: .destructive) {
                deleteProfile(withId: header.id)
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
                    logger.log(.core, .error, "Unable to start web receiver: \(error)")
                    errorHandler.handle(error)
                }
            } else {
                webReceiverManager.stop()
            }
       }
    }

    func deleteProfile(withId profileId: ABI.AppIdentifier) {
        Task {
            await profileObservable.remove(withId: profileId)
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

    let profileObservable: ProfileObservable

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
            profileObservable: profileObservable,
            errorHandler: errorHandler
        )
    }
}

// MARK: - Preview

// FIXME: #1594, Previews
//#Preview("Empty") {
//    ProfilesView(
//        profileObservable: ProfileManager(profiles: []),
//        webReceiverManager: .forPreviews
//    )
//    .withMockEnvironment()
//}
//
//#Preview("Profiles") {
//    ProfilesView(
//        profileObservable: .forPreviews,
//        webReceiverManager: .forPreviews
//    )
//    .withMockEnvironment()
//}
