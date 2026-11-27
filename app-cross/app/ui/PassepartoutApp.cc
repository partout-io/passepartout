// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "../business/strategy/ConfigurationFiles.h"
#include "PassepartoutApp.h"
#include "../context/AppLog.h"
#include "app/MainView.h"
#include "extensions/Models+UI.h"
#include "platform/Presentation.h"
#include "platform/ConfigurationPicker.h"
#include "../strings/Strings.h"
#include <wx/stdpaths.h>
#include <wx/weakref.h>
#include <wx/uilocale.h>

namespace {
std::string SingleInstanceKey() {
    // Scope both the instance lock and activation channel to the user.
    auto key = Passepartout::CrossConstants.app.name + "-" + wxGetUserId().ToStdString(wxConvUTF8);
    return key;
}
}

using namespace Passepartout;

bool PassepartoutApp::OnInit() {
    MainThread::SetDispatcher([this](std::function<void()> action) {
        CallAfter(std::move(action));
    });
    // Configure native appearance, localization, and application identity.
    UseSystemAppearance(*this);
    wxUILocale::UseDefault();
    AppLog::Write(AppLog::Level::info, AppLog::Category::core, "Start application");
    SetAppName(wxString::FromUTF8(CrossConstants.app.name));

    // Parse the launch mode and configuration paths.
    bool demo = false;
    std::vector<std::filesystem::path> files;
    for (int i = 1; i < argc; ++i) {
        const wxString arg(argv[i]);
        if (arg == wxString::FromUTF8(CrossConstants.command_line.demo_argument)) demo = true;
        else files.push_back(Paths::FromString(arg));
    }

    // Prefer brokered activation files; preserve read failures for import reporting.
    std::shared_ptr<const ConfigurationFiles> activation_files;
    try {
        activation_files = FileActivation::ReadFiles();
    } catch (...) {
        AppLog::Write(AppLog::Level::error, AppLog::Category::core, "Unable to read activation files");
        activation_files = std::make_shared<FileConfigurationFiles>(std::vector<std::filesystem::path>{}, 1);
    }
    if (!activation_files) activation_files = std::make_shared<FileConfigurationFiles>(files);

    // Forward to the existing instance, or claim this launch as the primary instance.
    const auto data_root = Paths::FromString(wxStandardPaths::Get().GetUserLocalDataDir());
    const auto instance_key = SingleInstanceKey();
    instance_ = std::make_unique<wxSingleInstanceChecker>(wxString::FromUTF8(instance_key));
    if (instance_->IsAnotherRunning()) {
        if (FileActivation::Forward(instance_key, activation_files)) return false;
        AppLog::Write(AppLog::Level::error, AppLog::Category::core, "Unable to forward activation to the running instance");
        if (activation_files->Count() || activation_files->SelectionFailures()) {
            PresentError(nullptr, StringKey::ErrorsAppImportGeneric);
        }
        return false;
    }

    const char *stage = "creating application context";
    try {
        // Assemble shared state and create the main presentation surface.
        context_ = std::make_unique<AppContext>(
            data_root, Constants::Load(), CrossConstants, demo
        );
        stage = "creating main window";
        AppLog::Write(AppLog::Level::debug, AppLog::Category::core, "Create main window");
        auto *view = new MainView(*context_, demo);
        SetTopWindow(view);

        // Receive subsequent activations before processing the initial import.
        stage = "registering file activation";
        const wxWeakRef<MainView> target(view);
        activation_ = std::make_unique<FileActivation>(instance_key, [target](auto files) {
            if (!target || target->IsBeingDeleted()) return false;
            target->Activate(std::move(files));
            return true;
        });
        stage = "processing initial file activation";
        view->Activate(std::move(activation_files));

        // Refresh shared state whenever the application returns to the foreground.
        stage = "binding application events";
        Bind(wxEVT_ACTIVATE_APP, [this](wxActivateEvent &event) {
            if (event.GetActive()) {
                context_->tunnel.Refresh();
                context_->config.Refresh();
                context_->version.Check();
            }
            event.Skip();
        });

        // Show the fully connected main window.
        stage = "showing main window";
        view->Show();
        AppLog::Write(AppLog::Level::info, AppLog::Category::core, "Main window shown");
        return true;
    } catch (...) {
        AppLog::Write(AppLog::Level::error, AppLog::Category::core,
            std::string("Application startup failed while ") + stage);
    }
    PresentError(nullptr, StringKey::ErrorsAppOther);
    return false;
}

int PassepartoutApp::OnExit() {
    // Stop accepting activations before releasing application state and the instance lock.
    activation_.reset();
    context_.reset();
    MainThread::SetDispatcher({});
    instance_.reset();
    return wxApp::OnExit();
}
