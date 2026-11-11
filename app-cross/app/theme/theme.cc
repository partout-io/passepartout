// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "theme.h"
#ifdef __WXMSW__
#include "switch.h"
#endif
#include "app_icon_resource.h"
#include "../strings/strings.h"
#include <wx/imagpng.h>
#include <wx/mstream.h>
#include <wx/settings.h>
namespace Passepartout {
wxIcon Theme::AppIcon(wxWindow *window) {
    wxMemoryInputStream stream(appIconData, sizeof(appIconData));
    wxPNGHandler decoder;
    wxImage image;
    if (!decoder.LoadFile(&image, stream)) return {};
    const auto fallback = window->FromDIP(16);
    const auto width = wxSystemSettings::GetMetric(wxSYS_SMALLICON_X, window);
    const auto height = wxSystemSettings::GetMetric(wxSYS_SMALLICON_Y, window);
    image.Rescale(width > 0 ? width : fallback, height > 0 ? height : fallback,
                  wxIMAGE_QUALITY_HIGH);
    wxIcon icon;
    icon.CopyFromBitmap(wxBitmap(image));
    return icon;
}
int Theme::Spacing(wxWindow *window) {
    return window->FromDIP(12);
}
void Theme::Apply(wxWindow *window) {
    window->SetBackgroundColour(wxSystemSettings::GetColour(wxSYS_COLOUR_WINDOW));
    window->SetForegroundColour(wxSystemSettings::GetColour(wxSYS_COLOUR_WINDOWTEXT));
    window->Refresh();
}
wxActivityIndicator *ThemeProgressView(wxWindow *parent) {
    return new wxActivityIndicator(parent, wxID_ANY);
}
namespace {
class ProfileListStore final : public wxDataViewListStore {
public:
    bool IsEnabledByRow(unsigned row, unsigned column) const override {
        return column != ThemeProfileList::ToggleColumn || GetItemData(GetItem(row)) != 0;
    }
};
}
ThemeProfileList::ThemeProfileList(wxWindow *parent)
    : wxDataViewListCtrl(parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxDV_MULTIPLE | wxDV_ROW_LINES) {
    auto *store = new ProfileListStore;
    AssociateModel(store);
    store->DecRef();
    SetName(Localized(StringKey::GlobalNounsProfiles));
    AppendTextColumn(Localized(StringKey::GlobalNounsName), wxDATAVIEW_CELL_INERT, parent->FromDIP(230));
    AppendTextColumn(Localized(StringKey::GlobalNounsStatus), wxDATAVIEW_CELL_INERT, parent->FromDIP(140));
    AppendTextColumn(wxString(), wxDATAVIEW_CELL_INERT, parent->FromDIP(190));
#ifdef __WXMSW__
    AppendColumn(new wxDataViewColumn(wxString(),
        new ThemeSwitchRenderer(Localized(StringKey::EntitiesTunnelStatusActive),
                                Localized(StringKey::EntitiesTunnelStatusInactive)),
        ToggleColumn, parent->FromDIP(90), wxALIGN_CENTER), "bool");
#else
    AppendToggleColumn(wxString(), wxDATAVIEW_CELL_ACTIVATABLE,
                       parent->FromDIP(90), wxALIGN_CENTER);
#endif
}
void ThemeProfileList::AppendProfile(const wxString &name, const wxString &status, bool isOn, bool enabled, const wxString &transfer) {
    wxVector<wxVariant> values;
    values.push_back(wxVariant(name));
    values.push_back(wxVariant(status));
    values.push_back(wxVariant(transfer));
    values.push_back(wxVariant(isOn));
    AppendItem(values, enabled ? 1 : 0);
}
void ThemeProfileList::UpdateProfile(unsigned row, const wxString &name, const wxString &status, bool isOn, bool enabled, const wxString &transfer) {
    SetItemData(RowToItem(row), enabled ? 1 : 0);
    SetTextValue(name, row, 0);
    SetTextValue(status, row, 1);
    SetToggleValue(isOn, row, ToggleColumn);
    SetTextValue(transfer, row, TransferColumn);
}
wxStaticText *ThemeEmptyMessage(wxWindow *parent, const wxString &message) {
    return new wxStaticText(parent, wxID_ANY, message, wxDefaultPosition, wxDefaultSize, wxALIGN_CENTER);
}
}
