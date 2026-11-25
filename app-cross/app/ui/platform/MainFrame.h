// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>

#ifdef __WXMSW__
#include <windows.h>

namespace Passepartout {
class MainFrame : public wxFrame {
public:
    using wxFrame::wxFrame;

    void ConfigureSystemMenu(const wxString &about_title) {
        if (auto menu = GetSystemMenu(static_cast<HWND>(GetHandle()), FALSE)) {
            InsertMenuW(menu, 0, MF_BYPOSITION | MF_SEPARATOR, 0, nullptr);
            InsertMenuW(menu, 0, MF_BYPOSITION | MF_STRING, SystemAbout, about_title.wc_str());
        }
    }

protected:
    WXLRESULT MSWWindowProc(WXUINT message, WXWPARAM w_param, WXLPARAM l_param) override {
        if (message == WM_SYSCOMMAND && (w_param & 0xfff0) == SystemAbout) {
            // Dispatch through the shared About action after native menu handling.
            wxQueueEvent(this, new wxCommandEvent(wxEVT_MENU, wxID_ABOUT));
            return 0;
        }
        return wxFrame::MSWWindowProc(message, w_param, l_param);
    }

private:
    static constexpr unsigned SystemAbout = 0x100;
};
}
#else
namespace Passepartout {
class MainFrame : public wxFrame {
public:
    using wxFrame::wxFrame;

    void ConfigureSystemMenu(const wxString &) {}
};
}
#endif
