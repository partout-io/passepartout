// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../theme/ThemeDetailView.h"
#include "../../strings/Strings.h"
#include <partout/models/IPSettings.h>
#include <wx/numformatter.h>
#include <type_traits>
#include <optional>

namespace Passepartout {
using OpenModuleContent = std::function<void(wxString, wxString)>;
class ModuleDetailView : public ThemeDetailView {
public:
    ModuleDetailView(wxWindow *parent, OpenModuleContent open_content,
        Presentation presentation = Presentation::Form);
    template<typename T>
    void Row(StringKey title, const T &value, bool long_content = false,
        const std::optional<wxString> &preview = std::nullopt, bool secure = false) {
        Row(Localized(title), value, long_content, preview, secure);
    }
    template<typename T>
    void Row(const wxString &title, const std::optional<T> &value, bool long_content = false,
        const std::optional<wxString> &preview = std::nullopt, bool secure = false) {
        if (value) Row(title, *value, long_content, preview, secure);
    }
    template<typename T>
    void Row(const wxString &title, const T &value, bool long_content = false,
        const std::optional<wxString> &preview = std::nullopt, bool secure = false) {
        const auto text = ValueText(value);
        if (text.empty()) return;
        if (long_content) {
            LongContent(title, preview.value_or(text), [this, title, text] {
                open_content_(title, text);
            }, secure);
        } else if constexpr (std::is_same_v<T, bool>) Field(title, text);
        else CopiableField(title, text);
    }
    void Row(const wxString &title, const std::vector<std::string> &values, bool long_content = false,
        const std::optional<wxString> &preview = std::nullopt, bool secure = false);
    void Duration(StringKey title, const std::optional<double> &value);
    void IP(const wxString &title, const std::optional<Partout::Models::IPSettings> &settings,
        const std::optional<std::vector<Partout::Models::Route>> &additional_routes = std::nullopt, bool open_vpn = false);
    static wxString ValueText(const std::string &value) {
        return wxString::FromUTF8(value);
    }
    static wxString ValueText(bool value) {
        return Localized(value ? StringKey::GlobalNounsEnabled : StringKey::GlobalNounsDisabled);
    }
    template<typename T, std::enable_if_t<std::is_arithmetic_v<T>, int> = 0>
    static wxString ValueText(T value) {
        // Ports and MTUs remain copyable protocol values without grouping separators.
        if constexpr (std::is_integral_v<T>) {
            return wxNumberFormatter::ToString(static_cast<long long>(value), wxNumberFormatter::Style_None);
        } else {
            return wxNumberFormatter::ToString(static_cast<double>(value), 2, wxNumberFormatter::Style_NoTrailingZeroes);
        }
    }
    template<typename T>
    static bool HasContent(const std::optional<T> &value) {
        return value && HasContent(*value);
    }
    template<typename T, std::enable_if_t<std::is_arithmetic_v<T>, int> = 0>
    static bool HasContent(T) {
        return true;
    }
    static bool HasContent(const std::string &value) {
        return !value.empty();
    }
    template<typename T>
    static bool HasContent(const std::vector<T> &value) {
        return !value.empty();
    }
protected:
    OpenModuleContent open_content_;
};
}
