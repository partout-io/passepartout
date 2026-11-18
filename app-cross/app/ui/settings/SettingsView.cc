// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "SettingsView.h"
#include "../../theme/ThemeList.h"
#include "../../theme/ThemeContentLink.h"
#include "../../theme/Theme.h"
#include "../../strings/Strings.h"
#include "../../strings/Unlocalized.h"
#include <algorithm>
#include <wx/settings.h>

namespace Passepartout {
namespace {
class SettingsListStore final : public wxDataViewListStore {
public:
    bool IsEnabledByRow(unsigned row, unsigned) const override {
        return GetItemData(GetItem(row)) != 0;
    }

};
}
SettingsView::SettingsView(wxWindow *parent, const wxString &version, const wxString &updateTitle,
    SettingsSection initial, std::function<void(SettingsSection)> selected)
    : wxPanel(parent) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    auto *list = new ThemeList(this, wxDV_NO_HEADER);
    list->SetName(Localized(StringKey::ViewsSettingsTitle));
    auto *store = new SettingsListStore;
    list->AssociateModel(store);
    store->DecRef();
    auto *caption = new wxDataViewTextRenderer("string", wxDATAVIEW_CELL_INERT, wxALIGN_LEFT);
    caption->EnableMarkup();
    list->AppendColumn(new wxDataViewColumn(wxString(), caption, 0, wxCOL_WIDTH_AUTOSIZE, wxALIGN_LEFT, 0), "string");
    auto append = [list](const wxString &title, wxUIntPtr section) {
        auto caption = title;
        caption.Replace("&", "&amp;");
        caption.Replace("<", "&lt;");
        caption.Replace(">", "&gt;");
        wxVector<wxVariant> values;
        values.push_back(wxVariant(caption));
        list->AppendItem(values, section);
    };
    auto page = [append](StringKey title, SettingsSection section) {
        append(Localized(title), static_cast<wxUIntPtr>(section));
    };
    page(StringKey::GlobalNounsPreferences, SettingsSection::Preferences);
    page(StringKey::ViewsSettingsLinksTitle, SettingsSection::Links);
    page(StringKey::ViewsSettingsCreditsTitle, SettingsSection::Credits);
    page(StringKey::ViewsDiagnosticsTitle, SettingsSection::Diagnostics);
    unsigned initialRow = 0;
    for (unsigned row = 0; row < list->GetItemCount(); ++row) {
        if (list->GetItemData(list->RowToItem(row)) == static_cast<wxUIntPtr>(initial)) initialRow = row;
    }
    list->SelectRow(initialRow);
    selectedRow_ = initialRow;
    const auto select = [this, list, selected](const wxDataViewItem &item) {
        if (!item.IsOk()) return;
        const auto target = list->GetItemData(item);
        if (!target) {
            list->SelectRow(selectedRow_);
            return;
        }
        const auto row = static_cast<unsigned>(list->ItemToRow(item));
        if (row == selectedRow_) return;
        selectedRow_ = row;
        const auto section = static_cast<SettingsSection>(target);
        selected(section);
    };
    list->Bind(wxEVT_DATAVIEW_SELECTION_CHANGED, [select](wxDataViewEvent &event) {
        select(event.GetItem());
    });
    list->Bind(wxEVT_CHAR_HOOK, [list, select](wxKeyEvent &event) {
        const auto key = event.GetKeyCode();
        if (key != WXK_UP && key != WXK_DOWN) {
            event.Skip();
            return;
        }
        const int step = key == WXK_DOWN ? 1 : -1;
        int row = list->GetSelectedRow() + step;
        while (row >= 0 && row < static_cast<int>(list->GetItemCount())) {
            if (list->GetItemData(list->RowToItem(row)) != 0) {
                list->SelectRow(row);
                list->SetCurrentItem(list->RowToItem(row));
                list->EnsureVisible(list->RowToItem(row));
                select(list->RowToItem(row));
                return;
            }
            row += step;
        }
    });
    auto metrics = [list] {
        int width = list->GetCharWidth() * 16;
        for (unsigned row = 0; row < list->GetItemCount(); ++row) {
            width = std::max(width, list->GetTextExtent(list->GetTextValue(row, 0)).x + 2 * Theme::Spacing(list));
        }
        list->SetMinSize(wxSize(width, list->GetCharHeight() * 8));
    };
    metrics();
    list->Bind(wxEVT_SIZE, [list](wxSizeEvent &event) {
        list->GetColumn(0)->SetWidth(std::max(1, list->GetClientSize().x - list->FromDIP(4)));
        event.Skip();
    });
    Bind(wxEVT_DPI_CHANGED, [this, metrics](wxDPIChangedEvent &event) {
        CallAfter([this, metrics] {
            metrics();
            Layout();
        });
        event.Skip();
    });
    if (!updateTitle.empty()) {
        layout->Add(new ThemeContentLink(this, updateTitle, [selected] {
            selected(SettingsSection::Update);
        }), 0, wxBOTTOM, Theme::Spacing(this));
    }
    layout->Add(list, 1, wxEXPAND);
    layout->Add(new wxStaticText(this, wxID_ANY, version), 0,
        wxALIGN_CENTER_HORIZONTAL | wxTOP, Theme::Spacing(this));
    SetSizer(layout);
}
}
