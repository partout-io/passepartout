// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "Theme.h"
#include "AppIconResource.h"
#include <wx/imagpng.h>
#include <wx/mstream.h>
#include <wx/settings.h>
namespace Passepartout {
wxIcon Theme::AppIcon(wxWindow *window, int sizeDIP) {
    wxMemoryInputStream stream(appIconData, sizeof(appIconData));
    wxPNGHandler decoder;
    wxImage image;
    if (!decoder.LoadFile(&image, stream)) return {};
    const auto fallback = window->FromDIP(16);
    const auto width = sizeDIP ? window->FromDIP(sizeDIP) : wxSystemSettings::GetMetric(wxSYS_SMALLICON_X, window);
    const auto height = sizeDIP ? window->FromDIP(sizeDIP) : wxSystemSettings::GetMetric(wxSYS_SMALLICON_Y, window);
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
void Theme::Monospace(wxWindow *window) {
    auto font = window->GetFont();
    const auto fixedFont = wxSystemSettings::GetFont(wxSYS_ANSI_FIXED_FONT);
    font.SetFamily(wxFONTFAMILY_TELETYPE);
    font.SetFaceName(fixedFont.GetFaceName());
    window->SetFont(font);
}
wxActivityIndicator *ThemeProgressView(wxWindow *parent) {
    auto *indicator = new wxActivityIndicator(parent, wxID_ANY);
#ifdef __WXMSW__
    // Buffer background erasure and dot painting together on Windows.
    indicator->SetDoubleBuffered(true);
#endif
    return indicator;
}
wxStaticText *ThemeEmptyMessage(wxWindow *parent, const wxString &message) {
    return new wxStaticText(parent, wxID_ANY, message, wxDefaultPosition, wxDefaultSize, wxALIGN_CENTER);
}
}
