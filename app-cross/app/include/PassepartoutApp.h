// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>
#include <wx/snglinst.h>
#include "../context/AppContext.h"
#ifdef _WIN32
#include "../platform/WindowsFileActivation.h"
#endif

class PassepartoutApp : public wxApp {
public:
    bool OnInit() override;
    int OnExit() override;
private:
    std::unique_ptr<wxSingleInstanceChecker> instance_;
    std::unique_ptr<Passepartout::AppContext> context_;
#ifdef _WIN32
    std::unique_ptr<Passepartout::WindowsFileActivation> activation_;
#endif
};
