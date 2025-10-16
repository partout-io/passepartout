// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileStorageSection: View {

    @EnvironmentObject
    private var configManager: ConfigManager

    @EnvironmentObject
    private var iapManager: IAPManager

    @Environment(\.distributionTarget)
    private var distributionTarget

    @ObservedObject
    var profileEditor: ProfileEditor

    @Binding
    var paywallReason: PaywallReason?

    var flow: ProfileCoordinator.Flow?

    var body: some View {
        if showsSharing {
            sharingSection
        }
        if configManager.canSendToTV {
            tvSection
        }
    }
}

private extension ProfileStorageSection {
    var sharingSection: some View {
        Group {
            sharingToggle
                .themeContainerEntry(
                    header: sharingHeader,
                    subtitle: sharingDescription
                )

            tvToggle
                .themeContainerEntry(
                    subtitle: sharingTVDescription
                )
                .disabled(!profileEditor.isShared)
        }
        .themeContainer(header: sharingHeader)
    }

    var sharingToggle: some View {
        Toggle(isOn: $profileEditor.isShared) {
            ThemeImageLabel(.cloudOn, inForm: true) {
                HStack {
                    Text(Strings.Unlocalized.iCloud)
                    PurchaseRequiredView(
                        requiring: sharingRequirements,
                        reason: $paywallReason
                    )
                }
            }
        }
    }
}

private extension ProfileStorageSection {
    var tvSection: some View {
        Button(Strings.Views.Profile.SendTv.title_compound) {
            flow?.onSendToTV()
        }
        .themeContainerWithSingleEntry(
            header: !showsSharing ? Strings.Unlocalized.appleTV : nil,
            footer: tvDescription,
            isAction: true
        )
    }

    var tvToggle: some View {
        Toggle(isOn: $profileEditor.isAvailableForTV) {
            ThemeImageLabel(.tvOn, inForm: true) {
                HStack {
                    Text(Strings.Modules.General.Rows.appletv_compound)
                    PurchaseRequiredView(
                        requiring: tvRequirements,
                        reason: $paywallReason
                    )
                }
            }
        }
    }
}

private extension ProfileStorageSection {
    var showsSharing: Bool {
        distributionTarget.supportsCloudKit
    }

    var sharingRequirements: Set<AppFeature> {
        profileEditor.isShared ? [.sharing] : []
    }

    var sharingHeader: String {
        Strings.Modules.General.Sections.Storage.header
    }

    var sharingDescription: String {
        Strings.Modules.General.Sections.Storage.Sharing.footer(Strings.Unlocalized.iCloud)
    }

    var sharingTVDescription: String {
        Strings.Modules.General.Sections.Storage.Tv.Icloud.footer
    }

    var tvRequirements: Set<AppFeature> {
        profileEditor.isShared && profileEditor.isAvailableForTV ? [.appleTV, .sharing] : []
    }

    var tvDescription: String {
        var desc = [Strings.Modules.General.Sections.Storage.Tv.Web.footer]
        desc.append(Strings.Modules.General.Sections.Storage.Tv.Footer.purchaseUnsupported)
        return desc.joined(separator: " ")
    }
}

#Preview {
    Form {
        ProfileStorageSection(
            profileEditor: ProfileEditor(),
            paywallReason: .constant(nil)
        )
    }
    .themeForm()
    .withMockEnvironment()
}
