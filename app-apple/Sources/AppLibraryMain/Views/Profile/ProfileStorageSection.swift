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

    @Environment(\.appConfiguration)
    private var appConfiguration

    let profileEditor: ProfileEditor

    @Binding
    var paywallReason: PaywallReason?

    var flow: ProfileCoordinator.Flow?

    var body: some View {
        if showsSharing {
            sharingSection
        }
        tvSection
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
        Toggle(isOn: profileEditor.binding(\.isShared)) {
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
        Toggle(isOn: profileEditor.binding(\.isAvailableForTV)) {
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
        appConfiguration.distributionTarget.supportsCloudKit
    }

    var sharingRequirements: Set<ABI.AppFeature> {
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

    var tvRequirements: Set<ABI.AppFeature> {
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
