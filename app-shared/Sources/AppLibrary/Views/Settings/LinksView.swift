// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct LinksView: View {

    @EnvironmentObject
    private var iapManager: IAPManager

    @Environment(\.distributionTarget)
    private var distributionTarget

    public init() {
    }

    public var body: some View {
        Form {
            supportSection
            webSection
            policySection
        }
        .themeForm()
    }
}

private extension LinksView {
    var constants: Constants {
        .shared
    }

    var appStoreId: String {
        BundleConfiguration.mainString(for: .appStoreId)
    }

    var supportSection: some View {
        Group {
            Link(Strings.Views.Settings.Links.Rows.joinCommunity, destination: constants.websites.subreddit)
            Link(Strings.Views.Settings.Links.Rows.openDiscussion, destination: constants.github.discussions)
//            if distributionTarget.supportsIAP && iapManager.isPayingUser {
//                Link(Strings.Views.Settings.Links.Rows.writeReview, destination: BundleConfiguration.urlForReview)
//            }
            if !distributionTarget.supportsIAP && !iapManager.isBeta {
                WebDonationLink()
            }
        }
        .themeSection(header: Strings.Views.Settings.Links.Sections.support)
    }

    var webSection: some View {
        Group {
            Link(Strings.Views.Settings.Links.Rows.homePage, destination: constants.websites.home)
            Link(Strings.Views.Settings.Links.Rows.blog, destination: constants.websites.blog)
        }
        .themeSection(header: Strings.Views.Settings.Links.Sections.web)
    }

    var policySection: some View {
        Section {
            Link(Strings.Views.Settings.Links.Rows.disclaimer, destination: constants.websites.disclaimer)
            Link(Strings.Views.Settings.Links.Rows.privacyPolicy, destination: constants.websites.privacyPolicy)
        }
    }
}

#Preview {
    LinksView()
}
