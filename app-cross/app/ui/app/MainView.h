// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../context/AppContext.h"
#include "../platform/ConfigurationPicker.h"
#include "../theme/Theme.h"
#include "../platform/MainFrame.h"
#include "ProfileListView.h"
#include "../extensions/StateObserver.h"
#include <deque>

class MainView final : public Passepartout::MainFrame {
public:
    MainView(Passepartout::AppContext &context, bool demo,
             Passepartout::ConfigurationPickerFactory picker_factory
    );
    ~MainView() override;
    void Quit();
    void Activate(std::shared_ptr<const Passepartout::ConfigurationFiles> files);
private:
    void Render();
    void UpdateActions();
    void Import();
    void PresentInteractiveLogin(Passepartout::InteractiveLogin login);
    void Edit(const std::string &id);
    void Remove(std::vector<std::string> ids);
    void UpdateState();
    void PresentOperationError();
    void ProcessActivations();
    void PollPicker(wxTimerEvent &);
    Passepartout::AppContext &context_;
    Passepartout::ProfileObservable::State profiles_;
    Passepartout::TunnelObservable::State tunnels_;
    Passepartout::ProfileListView *collection_;
    wxStaticText *message_;
    wxActivityIndicator *progress_;
    wxButton *import_;
    wxButton *remove_;
    wxTimer tunnel_timer_;
    wxTimer picker_timer_;
    std::deque<std::shared_ptr<const Passepartout::ConfigurationFiles>> activations_;
    std::unique_ptr<Passepartout::ConfigurationPicker> picker_;
    bool picking_ = false;
    bool presenting_ = false;
    Passepartout::StateObserver observer_;
};
