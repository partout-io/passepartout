// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "PassepartoutApp.h"
#include "business/extensions/AppLogger.h"
#include "ui/app/MainView.h"
#include "ui/extensions/FilePath.h"
#include "strings/Strings.h"
#include "partout.h"
#include <wx/stdpaths.h>
#include <wx/weakref.h>
#include <wx/uilocale.h>

namespace {
    std::string SingleInstanceKey(bool demo) {
        // Scope both the instance lock and activation channel to the user and mode.
        auto key = Passepartout::defaultCrossConstants.tags.app + "-" + wxGetUserId().ToStdString(wxConvUTF8);
        if (demo) key += Passepartout::defaultCrossConstants.commandLine.demoArgument;
        return key;
    }
}

using namespace Passepartout;

bool PassepartoutApp::OnInit() {
    // Configure native appearance, localization, and application identity.
#ifdef __WXMSW__
    // Windows needs an explicit opt-in; other ports follow the native theme.
    SetAppearance(Appearance::System);
#endif
    wxUILocale::UseDefault();
    AppLogger startupLogger;
    startupLogger.Write(LogLevel::info, LogCategory::core, "Start application");
    SetAppName(wxString::FromUTF8(defaultCrossConstants.tags.app));

    // Parse the launch mode and configuration paths.
    bool demo = false;
    std::vector<std::filesystem::path> files;
    for (int i = 1; i < argc; ++i) {
        const wxString arg(argv[i]);
        if (arg == wxString::FromUTF8(defaultCrossConstants.commandLine.demoArgument)) demo = true;
        else files.push_back(FilePath(arg));
    }

    // Prefer brokered activation files; preserve read failures for import reporting.
    std::shared_ptr<const ConfigurationFiles> activationFiles;
    try {
        activationFiles = FileActivation::ReadFiles();
    } catch (...) {
        startupLogger.Write(LogLevel::error, LogCategory::core, "Unable to read activation files");
        activationFiles = std::make_shared<ConfigurationFiles>(std::vector<std::filesystem::path>{}, 1);
    }
    if (!activationFiles) activationFiles = std::make_shared<ConfigurationFiles>(files);

    // Forward to the existing instance, or claim this launch as the primary instance.
    const auto dataRoot = FilePath(wxStandardPaths::Get().GetUserLocalDataDir());
    const auto instanceKey = SingleInstanceKey(demo);
    instance_ = std::make_unique<wxSingleInstanceChecker>(wxString::FromUTF8(instanceKey));
    if (instance_->IsAnotherRunning()) {
        if (FileActivation::Forward(instanceKey, activationFiles)) return false;
        startupLogger.Write(LogLevel::error, LogCategory::core, "Application startup rejected: another instance is running");
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
        context_ = std::make_unique<AppContext>(dataRoot, demo);
        stage = "creating main window";
        startupLogger.Write(LogLevel::debug, LogCategory::core, "Create main window");
        auto *view = new MainView(*context_, demo, MakeConfigurationPicker);
        SetTopWindow(view);

        // Receive subsequent activations before processing the initial import.
        stage = "registering file activation";
        const wxWeakRef<MainView> target(view);
        activation_ = std::make_unique<FileActivation>(instanceKey, [target](auto files) {
            if (!target || target->IsBeingDeleted()) return false;
            target->Activate(std::move(files));
            return true;
        });
        stage = "processing initial file activation";
        view->Activate(std::move(activationFiles));

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
        startupLogger.Write(LogLevel::info, LogCategory::core, "Main window shown");
        return true;
    } catch (...) {
        startupLogger.Write(LogLevel::error, LogCategory::core,
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
