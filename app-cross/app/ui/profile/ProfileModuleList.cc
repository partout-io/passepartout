// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ProfileModuleList.h"
#include "../extensions/Module.h"
#include "../../strings/Strings.h"
#include "../../theme/Theme.h"
#include <algorithm>
#include <type_traits>
#include <wx/settings.h>

namespace Passepartout {
namespace {
class ModuleListStore final : public wxDataViewListStore {
public:
    bool HasValue(const wxDataViewItem &item, unsigned column) const override {
        return column != 0 || GetRow(item) != 0;
    }
    bool IsEnabledByRow(unsigned, unsigned column) const override {
        return column != 0;
    }

};
}
ProfileModuleList::ProfileModuleList(wxWindow *parent, const ProfileEditor &editor,
    std::function<void(std::size_t)> selected)
    : ThemeList(parent, wxDV_NO_HEADER) {
    SetName(Localized(StringKey::GlobalNounsModules));
    auto *store = new ModuleListStore;
    AssociateModel(store);
    store->DecRef();
    AppendToggleColumn(wxString(), wxDATAVIEW_CELL_INERT, wxCOL_WIDTH_AUTOSIZE, wxALIGN_CENTER, 0);
    AppendTextColumn(wxString(), wxDATAVIEW_CELL_INERT, wxCOL_WIDTH_AUTOSIZE, wxALIGN_LEFT, 0);
    wxVector<wxVariant> general;
    general.push_back(wxVariant(false));
    general.push_back(wxVariant(Localized(StringKey::GlobalNounsGeneral)));
    AppendItem(general, 1);
    const auto draft = editor.Snapshot().draft;
    for (std::size_t index = 0; index < draft.modules.size(); ++index) {
        const auto &module = draft.modules[index];
        if (std::holds_alternative<Partout::Models::TaggedModuleCustom>(module)) continue;
        const bool enabled = std::visit([&](const auto &tagged) {
            if constexpr (std::is_same_v<std::decay_t<decltype(tagged)>, Partout::Models::TaggedModuleCustom>) {
                return false;
            } else {
                return std::find(draft.activeModulesIds.begin(), draft.activeModulesIds.end(),
                    tagged.value.id) != draft.activeModulesIds.end();
            }
        }, module);
        wxVector<wxVariant> cells;
        cells.push_back(wxVariant(enabled));
        cells.push_back(wxVariant(ModuleTitle(module)));
        AppendItem(cells, index + 2);
    }
    SelectRow(0);
    const auto select = [this, selected](const wxDataViewItem &item) {
        if (!item.IsOk()) return;
        const auto target = GetItemData(item);
        const auto row = static_cast<unsigned>(ItemToRow(item));
        if (row == selectedRow_) return;
        selectedRow_ = row;
        selected(target - 1);
    };
    Bind(wxEVT_DATAVIEW_SELECTION_CHANGED, [select](wxDataViewEvent &event) {
        select(event.GetItem());
    });
    Bind(wxEVT_CHAR_HOOK, [this, select](wxKeyEvent &event) {
        const auto key = event.GetKeyCode();
        if (key != WXK_UP && key != WXK_DOWN) {
            event.Skip();
            return;
        }
        const int step = key == WXK_DOWN ? 1 : -1;
        const int row = GetSelectedRow() + step;
        if (row < 0 || row >= static_cast<int>(GetItemCount())) return;
        const auto item = RowToItem(row);
        SelectRow(row);
        SetCurrentItem(item);
        EnsureVisible(item);
        select(item);
    });
    UpdateMetrics();
    Bind(wxEVT_DPI_CHANGED, [this](wxDPIChangedEvent &event) {
        CallAfter([this] {
            UpdateMetrics();
            GetParent()->Layout();
        });
        event.Skip();
    });
}
void ProfileModuleList::UpdateMetrics() {
    const int padding = 2 * Theme::Spacing(this);
    const int checkboxWidth = std::max(GetCharHeight(), GetColumn(0)->GetRenderer()->GetSize().x) + padding;
    GetColumn(0)->SetWidth(checkboxWidth);
    int titleWidth = 0;
    for (unsigned row = 0; row < GetItemCount(); ++row) {
        titleWidth = std::max(titleWidth, GetTextExtent(GetTextValue(row, 1)).x);
    }
    titleWidth += padding;
    GetColumn(1)->SetWidth(titleWidth);
    int width = checkboxWidth + titleWidth;
    width += std::max(0, wxSystemSettings::GetMetric(wxSYS_VSCROLL_X, this));
    SetMinSize(ClientToWindowSize(wxSize(width, GetCharHeight() * 6)));
}
}
