// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "../extensions/ConfigurationPickerFactory.h"
#ifdef _WIN32
#include "WindowsConfigurationPicker.h"
#include <wx/window.h>

namespace Passepartout {
std::unique_ptr<ConfigurationPicker> MakeConfigurationPicker(wxWindow &owner) {
    return MakeWindowsConfigurationPicker(owner.GetHandle());
}
}
#else
#include "../extensions/ModalConfigurationPicker.h"
#include "../extensions/FilePath.h"
#include "../../strings/Strings.h"
#include <wx/filedlg.h>

namespace Passepartout {
std::unique_ptr<ConfigurationPicker> MakeConfigurationPicker(wxWindow &owner) {
    return std::make_unique<ModalConfigurationPicker>([&owner]() -> ConfigurationPickerResult {
        wxFileDialog dialog(&owner, Localized(StringKey::ViewsAppToolbarImportFile), "", "",
            wxFileSelectorDefaultWildcardStr, wxFD_OPEN | wxFD_FILE_MUST_EXIST | wxFD_MULTIPLE);
        if (dialog.ShowModal() != wxID_OK) return {};
        wxArrayString selected;
        dialog.GetPaths(selected);
        std::vector<std::filesystem::path> paths;
        for (const auto &path : selected) paths.push_back(FilePath(path));
        return {std::make_shared<ConfigurationFiles>(std::move(paths)), false};
    });
}
}
#endif
