// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include StringKey::ThemeH
#include "../strings/strings.h"
#include <wx/settings.h>
namespace Passepartout {
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
wxListCtrl *ThemeList(wxWindow *parent) {
    auto *list = new wxListCtrl(parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT);
    list->SetName(Localized(StringKey::GlobalNounsProfiles));
    list->AppendColumn(Localized(StringKey::GlobalNounsName), wxLIST_FORMAT_LEFT, parent->FromDIP(320));
    list->AppendColumn(Localized(StringKey::GlobalNounsStatus), wxLIST_FORMAT_LEFT, parent->FromDIP(160));
    return list;
}
wxStaticText *ThemeEmptyMessage(wxWindow *parent, const wxString &message) {
    return new wxStaticText(parent, wxID_ANY, message, wxDefaultPosition, wxDefaultSize, wxALIGN_CENTER);
}
}
