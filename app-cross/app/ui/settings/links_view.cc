// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "links_view.h"
#include "../presentation.h"

namespace Passepartout {
LinksView::LinksView(wxWindow *parent, const Models::AppConstants &constants) : ThemeDetailView(parent) {
    const auto link = [this](StringKey key, std::string url) {
        Navigate(Localized(key), [this, url = std::move(url)] {
            OpenURL(this, url);
        });
    };
    Section(Localized(StringKey::ViewsSettingsLinksSectionsSupport));
    link(StringKey::ViewsSettingsLinksRowsOpenDiscussion, constants.github.discussionsURL);
    Section(Localized(StringKey::ViewsSettingsLinksSectionsWeb));
    link(StringKey::ViewsSettingsLinksRowsHomePage, constants.websites.homeURL);
    link(StringKey::ViewsSettingsLinksRowsBlog, constants.websites.partoutURL + "/blog");
    link(StringKey::ViewsSettingsLinksRowsDisclaimer, constants.websites.homeURL + "/disclaimer");
    link(StringKey::ViewsSettingsLinksRowsPrivacyPolicy, constants.websites.homeURL + "/privacy");
    Finish();
}
}
