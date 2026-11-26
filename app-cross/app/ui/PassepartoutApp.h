// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>
#include <wx/snglinst.h>
#include "../observables/AppContext.h"
#include "platform/FileActivation.h"

class PassepartoutApp : public wxApp {
public:
    bool OnInit() override;
    int OnExit() override;
private:
    std::unique_ptr<wxSingleInstanceChecker> instance_;
    std::unique_ptr<Passepartout::AppContext> context_;
    std::unique_ptr<Passepartout::FileActivation> activation_;
};
