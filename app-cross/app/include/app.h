// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>
#include <wx/snglinst.h>
#include "../context/app_context.h"
#ifdef _WIN32
#include "../platform/windows_file_activation.h"
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
