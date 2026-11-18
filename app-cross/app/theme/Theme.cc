// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "Theme.h"
#include "AppIconResource.h"
#include <wx/imagpng.h>
#include <wx/mstream.h>
#include <wx/settings.h>
#include <wx/artprov.h>
#include <wx/bmpbndl.h>
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
wxIcon Theme::SettingsIcon(wxWindow *window) {
    const int metric = wxSystemSettings::GetMetric(wxSYS_SMALLICON_X, window);
    const int size = metric > 0 ? metric : window->FromDIP(16);
    // Allow platform/application art providers to supply their settings artwork.
    auto icon = wxArtProvider::GetIcon("preferences-system", wxART_FRAME_ICON, wxSize(size, size));
    if (icon.IsOk()) return icon;
    // Shared scalable gear fallback: no platform-specific drawing or bitmap size.
    const auto colour = wxSystemSettings::GetColour(wxSYS_COLOUR_WINDOWTEXT).GetAsString(wxC2S_HTML_SYNTAX);
    const auto svg = wxString::Format(
        R"svg(<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="%s" fill-rule="evenodd" d="M19.500 12.000 L21.808 13.951 L21.239 15.827 L18.236 16.167 L17.303 17.303 L17.556 20.315 L15.827 21.239 L13.463 19.356 L12.000 19.500 L10.049 21.808 L8.173 21.239 L7.833 18.236 L6.697 17.303 L3.685 17.556 L2.761 15.827 L4.644 13.463 L4.500 12.000 L2.192 10.049 L2.761 8.173 L5.764 7.833 L6.697 6.697 L6.444 3.685 L8.173 2.761 L10.537 4.644 L12.000 4.500 L13.951 2.192 L15.827 2.761 L16.167 5.764 L17.303 6.697 L20.315 6.444 L21.239 8.173 L19.356 10.537 Z M16 12 A4 4 0 1 0 8 12 A4 4 0 1 0 16 12 Z"/></svg>)svg",
        colour);
    const auto bundle = wxBitmapBundle::FromSVG(svg.utf8_str(), wxSize(size, size));
    if (bundle.IsOk()) icon.CopyFromBitmap(bundle.GetBitmap(wxSize(size, size)));
    return icon;
}
int Theme::Spacing(wxWindow *window, Space space) {
    switch (space) {
        case Space::Row: return window->FromDIP(4);
        case Space::SectionContent: return window->FromDIP(6);
        case Space::Columns: return window->FromDIP(24);
        case Space::Section: return window->FromDIP(12);
    }
    return window->FromDIP(12);
}
void Theme::Apply(wxWindow *window) {
    window->SetBackgroundColour(wxSystemSettings::GetColour(wxSYS_COLOUR_WINDOW));
    window->SetForegroundColour(wxSystemSettings::GetColour(wxSYS_COLOUR_WINDOWTEXT));
    window->Refresh();
}
void Theme::Monospace(wxWindow *window) {
    const auto inherited = window->GetFont();
    // Request a scalable monospace family at the inherited UI text size.
    // The legacy ANSI fixed stock font may select a small bitmap face.
    auto font = wxFont(wxFontInfo(inherited.GetFractionalPointSize())
        .Family(wxFONTFAMILY_TELETYPE)
        .Weight(inherited.GetWeight())
        .Style(inherited.GetStyle()));
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
