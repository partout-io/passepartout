// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../observables/AppContext.h"
#include "../extensions/Models+UI.h"
#include "../theme/Theme.h"
#include "../platform/MainFrame.h"
#include "ProfileListView.h"
#include <deque>

class MainView final : public Passepartout::MainFrame {
public:
    MainView(Passepartout::AppContext &context, bool demo,
             Passepartout::Configuration::PickerFactory picker_factory
    );
    ~MainView() override;
    void Quit();
    void Activate(std::shared_ptr<const Passepartout::ConfigurationFiles> files);
private:
    void Render();
    void UpdateActions();
    void Import();
    void PresentInteractiveLogin();
    void Edit(const std::string &id);
    void Remove(std::vector<std::string> ids);
    void Tick(wxTimerEvent &);
    Passepartout::AppContext &context_;
    Passepartout::ProfileObservable::State profiles_;
    Passepartout::TunnelObservable::State tunnels_;
    Passepartout::SerialExecutor::Activity activity_;
    Passepartout::ProfileListView *collection_;
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
