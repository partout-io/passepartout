// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ModuleDetailView.h"
#include <wx/numformatter.h>

namespace Passepartout {
ModuleDetailView::ModuleDetailView(wxWindow *parent, OpenModuleContent open_content, Presentation presentation)
    : ThemeDetailView(parent, presentation), open_content_(std::move(open_content)) {}

void ModuleDetailView::Row(const wxString &title, const std::vector<std::string> &values, bool long_content,
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
    if (IsForm() && !long_content) Items(title, items);
    else Row(title, text.ToStdString(wxConvUTF8), long_content, preview, secure);
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
    const std::optional<std::vector<Partout::Models::Route>> &additional_routes, bool open_vpn) {
    const auto &ip = settings.value_or(Partout::Models::IPSettings{});
    auto included = ip.includedRoutes;
    if (additional_routes) included.insert(included.end(), additional_routes->begin(), additional_routes->end());
    if (ip.subnets.empty() && included.empty() && ip.excludedRoutes.empty()) return;
    Section(title);
    if (open_vpn && !ip.subnets.empty()) {
        const auto &host = ip.subnets.front();
        Row(StringKey::GlobalNounsAddress, host.substr(0, host.find('/')));
    } else Row(StringKey::GlobalNounsAddress, ip.subnets);
    if (open_vpn) {
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
