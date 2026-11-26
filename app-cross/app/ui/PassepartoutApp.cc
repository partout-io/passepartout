// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "PassepartoutApp.h"
#include "../context/AppLogger.h"
#include "app/MainView.h"
#include "extensions/Models+UI.h"
#include "platform/Presentation.h"
#include "../strings/Strings.h"
#include "partout.h"
#include <wx/stdpaths.h>
#include <wx/weakref.h>
#include <wx/uilocale.h>

namespace {
std::string SingleInstanceKey(bool demo) {
    // Scope both the instance lock and activation channel to the user and mode.
    auto key = Passepartout::DefaultCrossConstants.tags.app + "-" + wxGetUserId().ToStdString(wxConvUTF8);
    if (demo) key += Passepartout::DefaultCrossConstants.command_line.demo_argument;
    return key;
}
}

using namespace Passepartout;

bool PassepartoutApp::OnInit() {
    // Configure native appearance, localization, and application identity.
    UseSystemAppearance(*this);
    wxUILocale::UseDefault();
    AppLogger startup_logger;
    startup_logger.Write(LogLevel::info, LogCategory::core, "Start application");
    SetAppName(wxString::FromUTF8(DefaultCrossConstants.tags.app));

    // Parse the launch mode and configuration paths.
    bool demo = false;
    std::vector<std::filesystem::path> files;
    for (int i = 1; i < argc; ++i) {
        const wxString arg(argv[i]);
        if (arg == wxString::FromUTF8(DefaultCrossConstants.command_line.demo_argument)) demo = true;
        else files.push_back(Paths::FromString(arg));
    }

    // Prefer brokered activation files; preserve read failures for import reporting.
    std::shared_ptr<const ConfigurationFiles> activation_files;
    try {
        activation_files = FileActivation::ReadFiles();
    } catch (...) {
        startup_logger.Write(LogLevel::error, LogCategory::core, "Unable to read activation files");
        activation_files = std::make_shared<ConfigurationFiles>(std::vector<std::filesystem::path>{}, 1);
    }
    if (!activation_files) activation_files = std::make_shared<ConfigurationFiles>(files);

    // Forward to the existing instance, or claim this launch as the primary instance.
    const auto data_root = Paths::FromString(wxStandardPaths::Get().GetUserLocalDataDir());
    const auto instance_key = SingleInstanceKey(demo);
    instance_ = std::make_unique<wxSingleInstanceChecker>(wxString::FromUTF8(instance_key));
    if (instance_->IsAnotherRunning()) {
        if (FileActivation::Forward(instance_key, activation_files)) return false;
        startup_logger.Write(LogLevel::error, LogCategory::core, "Application startup rejected: another instance is running");
        wxMessageBox(Localized(StringKey::ErrorsAppOther),
                     wxTheApp->GetAppName(), wxOK | wxICON_INFORMATION);
        return false;
    }

    // Initialize the VPN runtime before assembling application dependencies.
    partout_init_args init{};
    init.log_level = PartoutLogLevelDebug;
    init.logs_private_data = false;
    init.logger_fn = AppLogger::PartoutMessage;
    partout_init(&init);
    const char *stage = "creating application context";
    try {
        // Assemble shared state and create the main presentation surface.
        context_ = std::make_unique<AppContext>(data_root, demo);
        stage = "creating main window";
        startup_logger.Write(LogLevel::debug, LogCategory::core, "Create main window");
        auto *view = new MainView(*context_, demo, Configuration::MakePicker);
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
        startup_logger.Write(LogLevel::info, LogCategory::core, "Main window shown");
        return true;
    } catch (...) {
        startup_logger.Write(LogLevel::error, LogCategory::core,
            std::string("Application startup failed while ") + stage);
    }

    wxMessageBox(Localized(StringKey::ErrorsAppOther), wxTheApp->GetAppName(), wxOK | wxICON_ERROR);
    return false;
}

int PassepartoutApp::OnExit() {
    // Stop accepting activations before releasing application state and the instance lock.
    activation_.reset();
    context_.reset();
    instance_.reset();
    return wxApp::OnExit();
}
