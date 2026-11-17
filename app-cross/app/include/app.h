// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <wx/wx.h>
#include <wx/srchctrl.h>
#include <wx/snglinst.h>
#include "../context/app_context.h"
#include "../ui/configuration_picker_factory.h"
#include "../theme/theme.h"
#include <deque>

class PassepartoutApp : public wxApp {
public:
    bool OnInit() override;
    int OnExit() override;
private:
    std::unique_ptr<wxSingleInstanceChecker> instance_;
    std::unique_ptr<Passepartout::AppContext> context_;
};

class MainView : public wxFrame {
public:
    MainView(Passepartout::AppContext &context, bool demo,
             std::vector<std::filesystem::path> files,
             Passepartout::ConfigurationPickerFactory pickerFactory);
    ~MainView() override;
    void Quit();
private:
    void Render();
    void UpdateActions();
    void Import();
    void Remove();
    void ToggleProfile(wxDataViewEvent &event);
    void Tick(wxTimerEvent &);
    std::vector<std::string> SelectedIds() const;
    Passepartout::AppContext &context_;
    Passepartout::AppSnapshot snapshot_;
    wxSearchCtrl *search_;
    Passepartout::ThemeProfileList *list_;
    wxStaticText *message_;
    wxActivityIndicator *progress_;
    wxButton *import_;
    wxButton *remove_;
    wxTimer timer_;
    std::vector<std::string> visibleIds_;
    std::vector<std::filesystem::path> pendingFiles_;
    std::unique_ptr<Passepartout::ConfigurationPicker> picker_;
    bool picking_ = false;
    unsigned ticks_ = 0;
    bool rendering_ = false;
};
