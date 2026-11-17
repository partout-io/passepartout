// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "module_detail_view.h"
#include <wx/numformatter.h>

namespace Passepartout {
ModuleDetailView::ModuleDetailView(wxWindow *parent, OpenModuleContent openContent)
    : ThemeDetailView(parent), openContent_(std::move(openContent)) {}
bool ModuleDetailView::HasContent(const nlohmann::json &value) {
    return !value.is_null() && (!value.is_structured() || !value.empty()) &&
        (!value.is_string() || !value.get<std::string>().empty());
}
wxString ModuleDetailView::ValueText(const nlohmann::json &value) {
    if (!HasContent(value)) return {};
    if (value.is_string()) return wxString::FromUTF8(value.get<std::string>());
    if (value.is_boolean()) return Localized(value.get<bool>() ? StringKey::GlobalNounsEnabled : StringKey::GlobalNounsDisabled);
    // Ports and MTUs remain copyable protocol values without grouping separators.
    if (value.is_number_integer()) return wxNumberFormatter::ToString(value.get<long long>(), wxNumberFormatter::Style_None);
    if (value.is_number()) return wxNumberFormatter::ToString(value.get<double>(), 2, wxNumberFormatter::Style_NoTrailingZeroes);
    if (value.is_array()) {
        wxString text;
        for (const auto &item : value) {
            const auto part = ValueText(item);
            if (part.empty()) continue;
            if (!text.empty()) text += "\n";
            text += part;
        }
        return text;
    }
    return wxString::FromUTF8(value.dump(2));
}
void ModuleDetailView::Row(const wxString &title, const nlohmann::json &value, bool longContent) {
    const auto text = ValueText(value);
    if (text.empty()) return;
    if (longContent) {
        Navigate(title, [this, title, text] {
            openContent_(title, text);
        }, text.BeforeFirst('\n'));
    } else Field(title, text);
}
void ModuleDetailView::Row(StringKey title, const nlohmann::json &value, bool longContent) {
    Row(Localized(title), value, longContent);
}
void ModuleDetailView::Duration(StringKey title, const nlohmann::json &value) {
    if (!value.is_number()) return;
    auto text = Localized(StringKey::GlobalNounsNSeconds);
    // The Apple catalog uses %@ for a preformatted duration quantity.
    text.Replace("%@", ValueText(value));
    text.Replace("%d", ValueText(value));
    Field(Localized(title), text);
}
void ModuleDetailView::IP(const wxString &title, const nlohmann::json &settings,
    const nlohmann::json &additionalRoutes, bool openVPN) {
    const auto ip = settings.is_object() ? settings : nlohmann::json::object();
    auto included = ip.value("includedRoutes", nlohmann::json::array());
    if (!included.is_array()) included = nlohmann::json::array();
    if (additionalRoutes.is_array()) {
        for (const auto &route : additionalRoutes) included.push_back(route);
    }
    const auto excluded = ip.value("excludedRoutes", nlohmann::json());
    auto address = ip.value("subnets", nlohmann::json());
    if (!HasContent(address) && !HasContent(included) && !HasContent(excluded)) return;
    Section(title);
    if (openVPN && address.is_array() && !address.empty()) {
        auto host = address.front().get<std::string>();
        address = host.substr(0, host.find('/'));
    }
    Row(StringKey::GlobalNounsAddress, address);
    if (openVPN) {
        const auto routes = ip.value("includedRoutes", nlohmann::json::array());
        for (const auto &route : routes) {
            if (route.value("destination", nlohmann::json()).is_null()) {
                Row(StringKey::GlobalNounsGateway, route.value("gateway", nlohmann::json()));
                break;
            }
        }
    }
    auto routes = [this](StringKey label, const nlohmann::json &values) {
        if (!values.is_array() || values.empty()) return;
        Section(Localized(label));
        for (const auto &route : values) {
            const auto destination = route.value("destination", nlohmann::json());
            if (destination.is_null()) Field(Localized(StringKey::GlobalNounsDestination), Localized(StringKey::GlobalNounsDefault));
            else Row(StringKey::GlobalNounsDestination, destination);
            Row(StringKey::GlobalNounsGateway, route.value("gateway", nlohmann::json()));
        }
    };
    routes(StringKey::ModulesIpRoutesIncluded, included);
    routes(StringKey::ModulesIpRoutesExcluded, excluded);
}
}
