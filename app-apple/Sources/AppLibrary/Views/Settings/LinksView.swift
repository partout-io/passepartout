// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct LinksView: View {
    @Environment(\.appConfiguration)
    private var appConfiguration

    private let isBeta: Bool

    public init(isBeta: Bool) {
        self.isBeta = isBeta
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
    var constants: ABI.AppConstants {
        appConfiguration.constants
    }

    var supportSection: some View {
        Group {
            Link(Strings.Views.Settings.Links.Rows.openDiscussion, destination: constants.github.discussionsURL)
//            if distributionTarget.supportsIAP && iapManager.isPayingUser {
//                Link(Strings.Views.Settings.Links.Rows.writeReview, destination: appConfiguration.urlForReview)
//            }
            if !appConfiguration.bundle.distributionTarget.supportsIAP && !isBeta {
                WebDonationLink()
            }
        }
        .themeSection(header: Strings.Views.Settings.Links.Sections.support)
    }

    var webSection: some View {
        Group {
            Link(Strings.Views.Settings.Links.Rows.homePage, destination: constants.websites.homeURL)
            Link(Strings.Views.Settings.Links.Rows.blog, destination: constants.websites.blogURL)
        }
        .themeSection(header: Strings.Views.Settings.Links.Sections.web)
    }

    var policySection: some View {
        Section {
            Link(Strings.Views.Settings.Links.Rows.disclaimer, destination: constants.websites.disclaimerURL)
            Link(Strings.Views.Settings.Links.Rows.privacyPolicy, destination: constants.websites.privacyPolicyURL)
        }
    }
}

#Preview {
    LinksView(isBeta: false)
}
