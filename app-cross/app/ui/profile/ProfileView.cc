// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "ProfileView.h"
#include "../extensions/Module.h"
#include "../Presentation.h"
#include "../../theme/Theme.h"
#include "../../theme/ThemeList.h"
#include "../../strings/Unlocalized.h"
#include <algorithm>
#include <type_traits>
#include <wx/clipbrd.h>
#include <wx/dataobj.h>
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
ProfileView::ProfileView(wxWindow *parent, std::shared_ptr<ProfileEditor> editor,
    std::function<void(std::size_t)> openModule, std::function<void()> changed)
    : wxPanel(parent) {
    Theme::Apply(this);
    const auto draft = editor->Snapshot().draft;
    const auto spacing = Theme::Spacing(this);
    auto *layout = new wxBoxSizer(wxVERTICAL);

    auto *nameRow = new wxBoxSizer(wxHORIZONTAL);
    nameRow->Add(new wxStaticText(this, wxID_ANY, Localized(StringKey::GlobalNounsName)),
        0, wxALIGN_CENTER_VERTICAL | wxRIGHT, spacing);
    auto *name = new wxTextCtrl(this, wxID_ANY, wxString::FromUTF8(draft.name));
    name->SetName(Localized(StringKey::GlobalNounsName));
    nameRow->Add(name, 1, wxALIGN_CENTER_VERTICAL);
    layout->Add(nameRow, 0, wxEXPAND | wxALL, spacing);
    name->Bind(wxEVT_TEXT, [editor, name, changed](wxCommandEvent &) {
        editor->Rename(name->GetValue().ToStdString(wxConvUTF8));
        changed();
    });

    auto *heading = new wxStaticText(this, wxID_ANY, Localized(StringKey::GlobalNounsModules));
    heading->SetFont(heading->GetFont().Bold());
    layout->Add(heading, 0, wxLEFT | wxRIGHT | wxBOTTOM, spacing);
    auto *modules = modules_ = new ThemeList(this, wxDV_NO_HEADER);
    modules->SetName(Localized(StringKey::GlobalNounsModules));
    auto *store = new ModuleListStore;
    modules->AssociateModel(store);
    store->DecRef();
    modules->AppendTextColumn(wxString(), wxDATAVIEW_CELL_INERT, wxCOL_WIDTH_AUTOSIZE, wxALIGN_LEFT, 0);
    modules->AppendTextColumn(wxString(), wxDATAVIEW_CELL_INERT, wxCOL_WIDTH_AUTOSIZE, wxALIGN_RIGHT, 0);
    for (std::size_t index = 0; index < draft.modules.size(); ++index) {
        const auto &module = draft.modules[index];
        if (std::holds_alternative<Partout::Models::TaggedModuleCustom>(module)) continue;
        const bool enabled = std::visit([&](const auto &tagged) {
            if constexpr (std::is_same_v<std::decay_t<decltype(tagged)>, Partout::Models::TaggedModuleCustom>) return false;
            else return std::find(draft.activeModulesIds.begin(), draft.activeModulesIds.end(), tagged.value.id) != draft.activeModulesIds.end();
        }, module);
        wxVector<wxVariant> cells;
        cells.push_back(wxVariant(ModuleTitle(module)));
        cells.push_back(wxVariant(Localized(enabled ? StringKey::GlobalNounsEnabled : StringKey::GlobalNounsDisabled)));
        const bool navigable = !std::holds_alternative<Partout::Models::TaggedModuleOnDemand>(module);
        modules->AppendItem(cells, navigable ? index + 1 : 0);
    }
    modules->Bind(wxEVT_SIZE, [this](wxSizeEvent &event) {
        ResizeColumns();
        event.Skip();
    });
    modules->Bind(wxEVT_DATAVIEW_ITEM_ACTIVATED, [this, modules, openModule](wxDataViewEvent &event) {
        if (!event.GetItem().IsOk()) return;
        const auto target = modules->GetItemData(event.GetItem());
        if (!target) return;
        CallAfter([openModule, target] {
            openModule(target - 1);
        });
    });
    layout->Add(modules, 1, wxEXPAND | wxLEFT | wxRIGHT, spacing);

    const auto id = wxString::FromUTF8(draft.id);
    auto *footer = new wxBoxSizer(wxHORIZONTAL);
    footer->Add(new wxStaticText(this, wxID_ANY, Strings::Unlocalized::UUID),
        0, wxALIGN_CENTER_VERTICAL | wxRIGHT, spacing);
    footer->AddStretchSpacer();
    auto *value = new wxStaticText(this, wxID_ANY, id);
    footer->Add(value, 0, wxALIGN_CENTER_VERTICAL | wxRIGHT, spacing);
    auto *copy = new wxButton(this, wxID_COPY);
    copy->Bind(wxEVT_BUTTON, [this, id](wxCommandEvent &) {
        if (!wxTheClipboard->Open()) {
            PresentError(this);
            return;
        }
        const bool copied = wxTheClipboard->SetData(new wxTextDataObject(id));
        wxTheClipboard->Close();
        if (!copied) PresentError(this);
    });
    footer->Add(copy, 0, wxALIGN_CENTER_VERTICAL);
    layout->Add(footer, 0, wxEXPAND | wxALL, spacing);
    SetSizer(layout);
    UpdateMetrics();
    Bind(wxEVT_DPI_CHANGED, [this](wxDPIChangedEvent &event) {
        CallAfter([this] {
            UpdateMetrics();
            GetParent()->InvalidateBestSize();
            GetParent()->Layout();
        });
        event.Skip();
    });
}
void ProfileView::UpdateMetrics() {
    const int padding = 2 * Theme::Spacing(this);
    int titleWidth = modules_->GetTextExtent(Localized(StringKey::GlobalNounsModules)).x;
    statusWidth_ = 0;
    const auto count = modules_->GetItemCount();
    for (unsigned row = 0; row < count; ++row) {
        titleWidth = std::max(titleWidth, modules_->GetTextExtent(modules_->GetTextValue(row, 0)).x);
        statusWidth_ = std::max(statusWidth_, modules_->GetTextExtent(modules_->GetTextValue(row, 1)).x);
    }
    statusWidth_ += padding;
    int rowHeight = modules_->GetCharHeight() + FromDIP(6);
    if (count) rowHeight = std::max(rowHeight, modules_->GetItemRect(modules_->RowToItem(0)).height);
    const int visibleRows = std::max(1, std::min(6, static_cast<int>(count)));
    const int scrollbar = std::max(0, wxSystemSettings::GetMetric(wxSYS_VSCROLL_X, modules_));
    modules_->SetMinSize(modules_->ClientToWindowSize(wxSize(
        titleWidth + padding + statusWidth_ + scrollbar, visibleRows * rowHeight)));
    InvalidateBestSize();
    ResizeColumns();
    Layout();
}
void ProfileView::ResizeColumns() {
    modules_->GetColumn(0)->SetWidth(std::max(1,
        modules_->GetClientSize().x - statusWidth_ - FromDIP(4)));
    modules_->GetColumn(1)->SetWidth(statusWidth_);
}
}
