// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "LinksView.h"
#include "../extensions/Presentation.h"
#include "../../strings/Unlocalized.h"

namespace Passepartout {
LinksView::LinksView(wxWindow *parent, const Models::AppConstants &constants) : ThemeDetailView(parent, Presentation::Plain) {
    const auto link = [this](StringKey key, std::string url) {
        ExternalLink(Localized(key), [this, url = std::move(url)] {
            OpenURL(this, url);
        });
    };
    Section(Localized(StringKey::ViewsSettingsLinksSectionsSupport));
    ExternalLink(Strings::Unlocalized::FAQ, [this, url = constants.websites.homeURL + "/faq"] {
        OpenURL(this, url);
    });
    link(StringKey::ViewsSettingsLinksRowsOpenDiscussion, constants.github.discussionsURL);
    Section(Localized(StringKey::ViewsSettingsLinksSectionsWeb));
    link(StringKey::ViewsSettingsLinksRowsHomePage, constants.websites.homeURL);
    link(StringKey::ViewsSettingsLinksRowsBlog, constants.websites.partoutURL + "/blog");
    link(StringKey::ViewsSettingsLinksRowsDisclaimer, constants.websites.homeURL + "/disclaimer");
    link(StringKey::ViewsSettingsLinksRowsPrivacyPolicy, constants.websites.homeURL + "/privacy");
    Finish();
}
}
