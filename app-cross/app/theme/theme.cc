// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "theme.h"
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
