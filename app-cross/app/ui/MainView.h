// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../context/AppContext.h"
#include "ConfigurationPickerFactory.h"
#include "../theme/Theme.h"
#include "ProfileCollectionView.h"
#include <deque>

class MainView : public wxFrame {
public:
    MainView(Passepartout::AppContext &context, bool demo,
             Passepartout::ConfigurationPickerFactory pickerFactory);
    ~MainView() override;
    void Quit();
    void Activate(std::shared_ptr<const Passepartout::ConfigurationFiles> files);
private:
#ifdef __WXMSW__
    WXLRESULT MSWWindowProc(WXUINT message, WXWPARAM wParam, WXLPARAM lParam) override;
#endif
    void Render();
    void UpdateActions();
    void Import();
    void PresentInteractiveLogin();
    void Edit(const std::string &id);
    void Remove(std::vector<std::string> ids);
    void Tick(wxTimerEvent &);
    Passepartout::AppContext &context_;
    Passepartout::AppSnapshot snapshot_;
    Passepartout::ProfileCollectionView *collection_;
    wxStaticText *message_;
    wxActivityIndicator *progress_;
    wxButton *import_;
    wxButton *remove_;
    wxTimer timer_;
    std::deque<std::shared_ptr<const Passepartout::ConfigurationFiles>> activations_;
    std::unique_ptr<Passepartout::ConfigurationPicker> picker_;
    bool picking_ = false;
    unsigned ticks_ = 0;
};
