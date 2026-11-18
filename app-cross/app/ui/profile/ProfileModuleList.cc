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
    bool IsEnabledByRow(unsigned row, unsigned) const override {
        return GetItemData(GetItem(row)) != 0;
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
    AppendTextColumn(wxString(), wxDATAVIEW_CELL_INERT, wxCOL_WIDTH_AUTOSIZE, wxALIGN_LEFT, 0);
    auto *enabledColumn = AppendToggleColumn(wxString(), wxDATAVIEW_CELL_INERT);
    // Activation editing is not implemented; keep its stock checkbox column hidden.
    enabledColumn->SetHidden(true);
    wxVector<wxVariant> general;
    general.push_back(wxVariant(Localized(StringKey::GlobalNounsGeneral)));
    general.push_back(wxVariant(false));
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
        cells.push_back(wxVariant(ModuleTitle(module)));
        cells.push_back(wxVariant(enabled));
        const bool navigable = !std::holds_alternative<Partout::Models::TaggedModuleOnDemand>(module);
        AppendItem(cells, navigable ? index + 2 : 0);
    }
    SelectRow(0);
    const auto select = [this, selected](const wxDataViewItem &item) {
        if (!item.IsOk()) return;
        const auto target = GetItemData(item);
        if (!target) {
            SelectRow(selectedRow_);
            return;
        }
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
        int row = GetSelectedRow() + step;
        while (row >= 0 && row < static_cast<int>(GetItemCount())) {
            const auto item = RowToItem(row);
            if (GetItemData(item) != 0) {
                SelectRow(row);
                SetCurrentItem(item);
                EnsureVisible(item);
                select(item);
                return;
            }
            row += step;
        }
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
    int width = 0;
    for (unsigned column = 0; column < 2; ++column) {
        if (GetColumn(column)->IsHidden()) continue;
        int columnWidth = 0;
        for (unsigned row = 0; row < GetItemCount(); ++row) {
            columnWidth = std::max(columnWidth, GetTextExtent(GetTextValue(row, column)).x);
        }
        columnWidth += padding;
        GetColumn(column)->SetWidth(columnWidth);
        width += columnWidth;
    }
    width += std::max(0, wxSystemSettings::GetMetric(wxSYS_VSCROLL_X, this));
    SetMinSize(ClientToWindowSize(wxSize(width, GetCharHeight() * 6)));
}
}
