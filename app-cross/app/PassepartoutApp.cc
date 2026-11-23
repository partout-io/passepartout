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

using namespace Passepartout;
namespace {
wxString Text(const std::string &value) {
    return wxString::FromUTF8(value);
}
}

bool PassepartoutApp::OnInit() {
#ifdef __WXMSW__
    // Windows needs an explicit opt-in; other ports follow the native theme.
    SetAppearance(Appearance::System);
#endif
    wxUILocale::UseDefault();
    AppLogger startupLogger;
    startupLogger.Write(LogLevel::info, LogCategory::core, "Start application");
    SetAppName(Text(defaultCrossConstants.tags.app));
    bool demo = false;
    std::vector<std::filesystem::path> files;
    for (int i = 1; i < argc; ++i) {
        const wxString arg(argv[i]);
        if (arg == Text(defaultCrossConstants.commandLine.demoArgument)) demo = true;
        else files.push_back(FilePath(arg));
    }
    std::shared_ptr<const ConfigurationFiles> activationFiles;
    try {
        activationFiles = FileActivation::ReadFiles();
    } catch (...) {
        activationFiles = std::make_shared<ConfigurationFiles>(std::vector<std::filesystem::path>{}, 1);
    }
    if (!activationFiles) activationFiles = std::make_shared<ConfigurationFiles>(files);
    const auto dataRoot = FilePath(wxStandardPaths::Get().GetUserLocalDataDir());
    const auto instanceName = Text(defaultCrossConstants.tags.app) + "-" + wxGetUserId() +
        (demo ? Text(defaultCrossConstants.commandLine.demoArgument) : wxString());
    instance_ = std::make_unique<wxSingleInstanceChecker>(instanceName);
    if (instance_->IsAnotherRunning()) {
        if (FileActivation::Forward(instanceName.ToStdString(wxConvUTF8), activationFiles)) return false;
        startupLogger.Write(LogLevel::error, LogCategory::core, "Application startup rejected: another instance is running");
        wxMessageBox(Localized(StringKey::ErrorsAppOther),
                     wxTheApp->GetAppName(), wxOK | wxICON_INFORMATION);
        return false;
    }
    partout_init_args init{};
    init.log_level = PartoutLogLevelDebug;
    init.logs_private_data = false;
    init.logger_fn = AppLogger::PartoutMessage;
    partout_init(&init);
    const char *stage = "creating application context";
    try {
        context_ = std::make_unique<AppContext>(dataRoot, demo);
        stage = "creating main window";
        startupLogger.Write(LogLevel::debug, LogCategory::core, "Create main window");
        auto *view = new MainView(*context_, demo, MakeConfigurationPicker);
        SetTopWindow(view);
        const wxWeakRef<MainView> target(view);
        activation_ = std::make_unique<FileActivation>(instanceName.ToStdString(wxConvUTF8), [target](auto files) {
            if (!target || target->IsBeingDeleted()) return false;
            target->Activate(std::move(files));
            return true;
        });
        view->Activate(std::move(activationFiles));
        Bind(wxEVT_ACTIVATE_APP, [this](wxActivateEvent &event) {
            if (event.GetActive()) {
                context_->tunnel.Refresh();
                context_->config.Refresh();
                context_->version.Check();
            }
            event.Skip();
        });
        stage = "showing main window";
        view->Show();
        startupLogger.Write(LogLevel::info, LogCategory::core, "Main window shown");
        return true;
    } catch (...) {
        startupLogger.Write(LogLevel::error, LogCategory::core, std::string("Application startup failed while ") + stage);
    }
    wxMessageBox(Localized(StringKey::ErrorsAppOther), wxTheApp->GetAppName(), wxOK | wxICON_ERROR);
    return false;
}
int PassepartoutApp::OnExit() {
    activation_.reset();
    context_.reset();
    instance_.reset();
    return wxApp::OnExit();
}
