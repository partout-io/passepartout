// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "SettingsView.h"
#include "../../theme/ThemeList.h"
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
    bool GetAttrByRow(unsigned row, unsigned, wxDataViewItemAttr &attribute) const override {
        const auto section = static_cast<SettingsSection>(GetItemData(GetItem(row)));
        if (section == SettingsSection::FAQ || section == SettingsSection::Update) {
            attribute.SetColour(wxSystemSettings::GetColour(wxSYS_COLOUR_HOTLIGHT));
            return true;
        }
        if (GetItemData(GetItem(row)) != 0) return false;
        attribute.SetBold(true);
        return true;
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
        if (section == static_cast<wxUIntPtr>(SettingsSection::FAQ) ||
            section == static_cast<wxUIntPtr>(SettingsSection::Update)) caption = "<u>" + caption + "</u>";
        wxVector<wxVariant> values;
        values.push_back(wxVariant(caption));
        list->AppendItem(values, section);
    };
    auto page = [append](StringKey title, SettingsSection section) {
        append(Localized(title), static_cast<wxUIntPtr>(section));
    };
    page(StringKey::GlobalNounsPreferences, SettingsSection::Preferences);
    if (!updateTitle.empty()) append(updateTitle, static_cast<wxUIntPtr>(SettingsSection::Update));
    append(Localized(StringKey::GlobalNounsAbout), 0);
    page(StringKey::GlobalNounsVersion, SettingsSection::Version);
    page(StringKey::ViewsSettingsLinksTitle, SettingsSection::Links);
    page(StringKey::ViewsSettingsCreditsTitle, SettingsSection::Credits);
    append(Localized(StringKey::GlobalNounsTroubleshooting), 0);
    append(Strings::Unlocalized::FAQ, static_cast<wxUIntPtr>(SettingsSection::FAQ));
    page(StringKey::ViewsDiagnosticsTitle, SettingsSection::Diagnostics);
    unsigned initialRow = 0;
    for (unsigned row = 0; row < list->GetItemCount(); ++row) {
        if (list->GetItemData(list->RowToItem(row)) == static_cast<wxUIntPtr>(initial)) initialRow = row;
    }
    list->SelectRow(initialRow);
    list->Bind(wxEVT_DATAVIEW_SELECTION_CHANGED,
        [list, selected, previous = initialRow](wxDataViewEvent &event) mutable {
            if (!event.GetItem().IsOk()) return;
            const auto item = list->GetItemData(event.GetItem());
            const auto section = static_cast<SettingsSection>(item);
            const bool external = section == SettingsSection::FAQ || section == SettingsSection::Update;
            if (!item) {
                list->SelectRow(previous);
                return;
            }
            previous = list->ItemToRow(event.GetItem());
            if (!external) selected(section);
        });
    list->Bind(wxEVT_DATAVIEW_ITEM_ACTIVATED, [list, selected](wxDataViewEvent &event) {
        if (!event.GetItem().IsOk()) return;
        const auto section = static_cast<SettingsSection>(list->GetItemData(event.GetItem()));
        if (section == SettingsSection::FAQ || section == SettingsSection::Update) selected(section);
    });
    list->Bind(wxEVT_CHAR_HOOK, [list](wxKeyEvent &event) {
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
    layout->Add(list, 1, wxEXPAND);
    layout->Add(new wxStaticText(this, wxID_ANY, version), 0,
        wxALIGN_CENTER_HORIZONTAL | wxTOP, Theme::Spacing(this));
    SetSizer(layout);
}
}
