// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../theme/ThemeDetailView.h"
#include "../../strings/Strings.h"
#include <partout/json.h>
#include <optional>

namespace Passepartout {
using OpenModuleContent = std::function<void(wxString, wxString)>;
class ModuleDetailView : public ThemeDetailView {
public:
    ModuleDetailView(wxWindow *parent, OpenModuleContent openContent,
        Presentation presentation = Presentation::Form);
    void Row(const wxString &title, const nlohmann::json &value, bool longContent = false,
        const std::optional<wxString> &preview = std::nullopt);
    void Row(StringKey title, const nlohmann::json &value, bool longContent = false,
        const std::optional<wxString> &preview = std::nullopt);
    void Duration(StringKey title, const nlohmann::json &value);
    void IP(const wxString &title, const nlohmann::json &settings,
        const nlohmann::json &additionalRoutes = nullptr, bool openVPN = false);
    static wxString ValueText(const nlohmann::json &value);
    static bool HasContent(const nlohmann::json &value);
protected:
    OpenModuleContent openContent_;
};
}
