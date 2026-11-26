// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "../../business/extensions/AppConstantsExtensions.h"
#include "LinksView.h"
#include "../platform/Presentation.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
LinksView::LinksView(wxWindow *parent, const Models::AppConstants &constants) : ThemeDetailView(parent, Presentation::Plain) {
    const auto link = [this](StringKey key, std::string url) {
        ExternalLink(Localized(key), [this, url = std::move(url)] {
            OpenURL(this, url);
        });
    };
    Section(Localized(StringKey::ViewsSettingsLinksSectionsSupport));
    ExternalLink(Strings::Unlocalized::FAQ, [this, url = Constants::FAQURL(constants.websites)] {
        OpenURL(this, url);
    });
    link(StringKey::ViewsSettingsLinksRowsOpenDiscussion, constants.github.discussionsURL);
    Section(Localized(StringKey::ViewsSettingsLinksSectionsWeb));
    link(StringKey::ViewsSettingsLinksRowsHomePage, constants.websites.homeURL);
    link(StringKey::ViewsSettingsLinksRowsBlog, Constants::BlogURL(constants.websites));
    link(StringKey::ViewsSettingsLinksRowsDisclaimer, Constants::DisclaimerURL(constants.websites));
    link(StringKey::ViewsSettingsLinksRowsPrivacyPolicy, Constants::PrivacyPolicyURL(constants.websites));
    Finish();
}
}
