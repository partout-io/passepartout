// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ModuleDetailView.h"
#include <wx/numformatter.h>

namespace Passepartout {
ModuleDetailView::ModuleDetailView(wxWindow *parent, OpenModuleContent openContent, Presentation presentation)
    : ThemeDetailView(parent, presentation), openContent_(std::move(openContent)) {}
void ModuleDetailView::Row(const wxString &title, const std::vector<std::string> &values, bool longContent,
    const std::optional<wxString> &preview, bool secure) {
    std::vector<wxString> items;
    wxString text;
    for (const auto &value : values) {
        if (value.empty()) continue;
        const auto item = ValueText(value);
        items.push_back(item);
        if (!text.empty()) text += "\n";
        text += item;
    }
    if (items.empty()) return;
    if (IsForm() && !longContent) Items(title, items);
    else Row(title, text.ToStdString(wxConvUTF8), longContent, preview, secure);
}
void ModuleDetailView::Duration(StringKey title, const std::optional<double> &value) {
    if (!value) return;
    auto text = Localized(StringKey::GlobalNounsNSeconds);
    // The Apple catalog uses %@ for a preformatted duration quantity.
    const auto quantity = wxNumberFormatter::ToString(*value, 2,
        wxNumberFormatter::Style_WithThousandsSep | wxNumberFormatter::Style_NoTrailingZeroes);
    text.Replace("%@", quantity);
    text.Replace("%d", quantity);
    Field(Localized(title), text);
}
void ModuleDetailView::IP(const wxString &title, const std::optional<Partout::Models::IPSettings> &settings,
    const std::optional<std::vector<Partout::Models::Route>> &additionalRoutes, bool openVPN) {
    const auto &ip = settings.value_or(Partout::Models::IPSettings{});
    auto included = ip.includedRoutes;
    if (additionalRoutes) included.insert(included.end(), additionalRoutes->begin(), additionalRoutes->end());
    if (ip.subnets.empty() && included.empty() && ip.excludedRoutes.empty()) return;
    Section(title);
    if (openVPN && !ip.subnets.empty()) {
        const auto &host = ip.subnets.front();
        Row(StringKey::GlobalNounsAddress, host.substr(0, host.find('/')));
    } else Row(StringKey::GlobalNounsAddress, ip.subnets);
    if (openVPN) {
        for (const auto &route : ip.includedRoutes) {
            if (!route.destination) {
                Row(StringKey::GlobalNounsGateway, route.gateway);
                break;
            }
        }
    }
    auto routes = [this](StringKey label, const std::vector<Partout::Models::Route> &values) {
        if (values.empty()) return;
        Section(Localized(label));
        for (const auto &route : values) {
            if (!route.destination) Field(Localized(StringKey::GlobalNounsDestination), Localized(StringKey::GlobalNounsDefault));
            else Row(StringKey::GlobalNounsDestination, route.destination);
            Row(StringKey::GlobalNounsGateway, route.gateway);
        }
    };
    routes(StringKey::ModulesIpRoutesIncluded, included);
    routes(StringKey::ModulesIpRoutesExcluded, ip.excludedRoutes);
}
}
