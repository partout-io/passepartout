// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "app.h"
#include "strings/strings.h"
#include "ui/extensions/app_profile.h"
#include "partout.h"
#include <wx/aboutdlg.h>
#include <wx/stdpaths.h>
#include <wx/stockitem.h>
#include <algorithm>
#include <set>

using namespace Passepartout;
namespace {
std::filesystem::path FilePath(const wxString &value) {
#ifdef _WIN32
    return std::filesystem::path(value.ToStdWstring());
#else
    return std::filesystem::u8path(value.ToStdString(wxConvUTF8));
#endif
}
wxString Text(const std::string &value) {
    return wxString::FromUTF8(value);
}
wxString StatusText(Status status) {
    switch (status) {
        case Status::disconnected: return Localized(StringKey::EntitiesTunnelStatusInactive);
        case Status::connecting: return Localized(StringKey::EntitiesTunnelStatusActivating);
        case Status::connected: return Localized(StringKey::EntitiesTunnelStatusActive);
        case Status::disconnecting: return Localized(StringKey::EntitiesTunnelStatusDeactivating);
        default: return Localized(StringKey::GlobalNounsUnknown);
    }
}
wxString TransferText(const AppSnapshot &state, const std::string &id) {
    if (!state.tunnelAvailable) return {};
    for (const auto &tunnel : state.tunnels) {
        if (tunnel.id != id || tunnel.status.value != Status::connected || !tunnel.transfer) continue;
        const auto &transfer = *tunnel.transfer;
        if (transfer.received < 0 || transfer.sent < 0) return {};
        return Text(Passepartout::TransferText(transfer));
    }
    return {};
}
wxString QuitTitle() {
    return wxGetStockLabel(wxID_EXIT) + "\tCtrl+Q";
}
class Tray final : public wxTaskBarIcon {
public:
    explicit Tray(MainView &view) : view_(view) {
        Bind(wxEVT_TASKBAR_LEFT_UP, [this](wxTaskBarIconEvent &) {
            view_.ShowWindow();
        });
    }
private:
    wxMenu *CreatePopupMenu() override {
        auto *menu = new wxMenu;
        menu->Append(wxID_STOP, Localized(StringKey::GlobalActionsDisconnect));
        menu->AppendSeparator();
        menu->Append(wxID_EXIT, QuitTitle());
        menu->Bind(wxEVT_MENU, [this](wxCommandEvent &) {
            view_.DisconnectActive();
        }, wxID_STOP);
        menu->Bind(wxEVT_MENU, [this](wxCommandEvent &) {
            view_.Quit();
        }, wxID_EXIT);
        return menu;
    }
    MainView &view_;
};
}

bool PassepartoutApp::OnInit() {
    AppLogger startupLogger;
    startupLogger.Write(LogLevel::info, "core", "Start application");
    SetAppName(Text(defaultCrossConstants.tags.app));
    bool demo = false;
    std::vector<std::filesystem::path> files;
    for (int i = 1; i < argc; ++i) {
        const wxString arg(argv[i]);
        if (arg == Text(defaultCrossConstants.commandLine.demoArgument)) demo = true;
        else files.push_back(FilePath(arg));
    }
    const auto dataRoot = FilePath(wxStandardPaths::Get().GetUserLocalDataDir());
    instance_ = std::make_unique<wxSingleInstanceChecker>(
        Text(defaultCrossConstants.tags.app) + "-" + wxGetUserId() +
        (demo ? Text(defaultCrossConstants.commandLine.demoArgument) : wxString()));
    if (instance_->IsAnotherRunning()) {
        startupLogger.Write(LogLevel::error, "core", "Application startup rejected: another instance is running");
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
        startupLogger.Write(LogLevel::debug, "core", "Create main window");
        auto *view = new MainView(*context_, demo, std::move(files));
        SetTopWindow(view);
        Bind(wxEVT_ACTIVATE_APP, [this](wxActivateEvent &event) {
            if (event.GetActive()) context_->tunnel.Refresh();
            event.Skip();
        });
        stage = "showing main window";
        view->Show();
        startupLogger.Write(LogLevel::info, "core", "Main window shown");
        return true;
    } catch (const std::exception &error) {
        startupLogger.Write(LogLevel::error, "core", std::string("Application startup failed while ") + stage + ": " + error.what());
    } catch (...) {
        startupLogger.Write(LogLevel::error, "core", std::string("Application startup failed while ") + stage);
    }
    wxMessageBox(Localized(StringKey::ErrorsAppOther), wxTheApp->GetAppName(), wxOK | wxICON_ERROR);
    return false;
}
int PassepartoutApp::OnExit() {
    context_.reset();
    instance_.reset();
    return wxApp::OnExit();
}
MainView::MainView(AppContext &context, bool demo, std::vector<std::filesystem::path> files)
    : wxFrame(nullptr, wxID_ANY, Text(context.crossConstants.tags.app) +
          (demo ? " (" + Text(context.crossConstants.commandLine.demoArgument) + ")" : wxString())),
      context_(context), timer_(this), pendingFiles_(std::move(files)) {
    auto *panel = new wxPanel(this);
    Theme::Apply(panel);
    const auto gap = Theme::Spacing(panel);
    auto *layout = new wxBoxSizer(wxVERTICAL);
    search_ = new wxSearchCtrl(panel, wxID_ANY);
    search_->ShowCancelButton(true);
    layout->Add(search_, 0, wxEXPAND | wxALL, gap);
    list_ = new ThemeProfileList(panel);
    layout->Add(list_, 1, wxEXPAND | wxLEFT | wxRIGHT, gap);
    message_ = ThemeEmptyMessage(panel, Localized(StringKey::GlobalNounsLoading));
    layout->Add(message_, 0, wxEXPAND | wxALL, gap);
    auto *actions = new wxBoxSizer(wxHORIZONTAL);
    import_ = new wxButton(panel, wxID_ADD, Localized(StringKey::ViewsAppToolbarImportFile));
    remove_ = new wxButton(panel, wxID_DELETE, Localized(StringKey::GlobalActionsRemove));
    progress_ = ThemeProgressView(panel);
    for (auto *button : {import_, remove_}) {
        actions->Add(button, 0, wxRIGHT, gap);
    }
    actions->AddStretchSpacer();
    actions->Add(progress_, 0, wxALIGN_CENTER_VERTICAL);
    layout->Add(actions, 0, wxEXPAND | wxALL, gap);
    panel->SetSizer(layout);
    auto *menus = new wxMenuBar;
    auto *file = new wxMenu;
    file->Append(wxID_ADD, Localized(StringKey::ViewsAppToolbarImportFile) + "\tCtrl+O");
    file->AppendSeparator();
    file->Append(wxID_EXIT, QuitTitle());
    menus->Append(file, wxGetStockLabel(wxID_FILE));
    auto *help = new wxMenu;
    help->Append(wxID_ABOUT, Localized(StringKey::GlobalNounsAbout));
    menus->Append(help, wxGetStockLabel(wxID_HELP));
    SetMenuBar(menus);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        Import();
    }, wxID_ADD);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        Quit();
    }, wxID_EXIT);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        wxAboutDialogInfo info;
        info.SetName(wxTheApp->GetAppName());
        info.SetVersion(Text(partout_version()));
        wxAboutBox(info, this);
    }, wxID_ABOUT);
    import_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        Import();
    });
    remove_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        Remove();
    });
    search_->Bind(wxEVT_TEXT, [this](wxCommandEvent &) {
        Render();
    });
    list_->Bind(wxEVT_DATAVIEW_SELECTION_CHANGED, [this](wxDataViewEvent &) {
        UpdateActions();
    });
    list_->Bind(wxEVT_DATAVIEW_ITEM_VALUE_CHANGED, &MainView::ToggleProfile, this);
    Bind(wxEVT_TIMER, &MainView::Tick, this);
    Bind(wxEVT_CLOSE_WINDOW, &MainView::CloseWindow, this);
    Bind(wxEVT_SYS_COLOUR_CHANGED, [panel](wxSysColourChangedEvent &event) {
        Theme::Apply(panel);
        event.Skip();
    });
    const auto icon = Theme::AppIcon(this);
    if (icon.IsOk()) SetIcon(icon);
    if (icon.IsOk() && wxTaskBarIcon::IsAvailable()) {
        tray_ = std::make_unique<Tray>(*this);
        if (!tray_->SetIcon(icon, wxTheApp->GetAppName())) tray_.reset();
    }
    SetMinSize(FromDIP(wxSize(640, 360)));
    SetSize(FromDIP(wxSize(720, 480)));
    Centre();
    snapshot_ = context_.profiles.Snapshot();
    Render();
    timer_.Start(200);
}
MainView::~MainView() {
    timer_.Stop();
    tray_.reset();
}
std::vector<std::string> MainView::SelectedIds() const {
    std::vector<std::string> ids;
    wxDataViewItemArray selected;
    list_->GetSelections(selected);
    for (const auto &item : selected) {
        const auto row = list_->ItemToRow(item);
        if (row >= 0 && static_cast<std::size_t>(row) < visibleIds_.size()) ids.push_back(visibleIds_[row]);
    }
    return ids;
}
void MainView::Render() {
    rendering_ = true;
    const auto selected = SelectedIds();
    list_->Freeze();
    const auto query = search_->GetValue().Lower();
    std::vector<std::string> ids;
    for (const auto &profile : snapshot_.profiles) {
        if (query.empty() || Text(profile.name).Lower().Contains(query)) ids.push_back(profile.id);
    }
    const bool rebuild = ids != visibleIds_;
    if (rebuild) list_->DeleteAllItems();
    visibleIds_ = std::move(ids);
    unsigned row = 0;
    for (const auto &profile : snapshot_.profiles) {
        if (!query.empty() && !Text(profile.name).Lower().Contains(query)) continue;
        const auto toggle = TunnelObservable::StateForProfile(snapshot_, profile.id);
        const auto status = snapshot_.tunnelAvailable &&
            snapshot_.tunnelObservationErrors.find(profile.id) == snapshot_.tunnelObservationErrors.end()
            ? StatusText(toggle.status) : wxString();
        const auto transfer = TransferText(snapshot_, profile.id);
        if (rebuild) list_->AppendProfile(Text(profile.name), status, toggle.isOn, toggle.canInteract, transfer);
        else list_->UpdateProfile(row, Text(profile.name), status, toggle.isOn, toggle.canInteract, transfer);
        if (rebuild && std::find(selected.begin(), selected.end(), profile.id) != selected.end())
            list_->SelectRow(row);
        ++row;
    }
    list_->Thaw();
    rendering_ = false;
    const bool tunnelUnavailable = !snapshot_.tunnelError.empty() || !snapshot_.reconciliationError.empty();
    message_->SetLabel(Localized(tunnelUnavailable ? StringKey::ErrorsAppTunnel : StringKey::ViewsAppFoldersNoProfiles));
    message_->Show(tunnelUnavailable || (snapshot_.loaded && snapshot_.profiles.empty()));
    const bool activity = snapshot_.HasActivity();
    if (activity) progress_->Start();
    else progress_->Stop();
    progress_->Show(activity);
    UpdateActions();
    GetChildren().GetFirst()->GetData()->Layout();
}
void MainView::UpdateActions() {
    const bool idle = !snapshot_.foregroundBusy && !snapshot_.pendingProfile && snapshot_.loaded;
    const auto selected = SelectedIds();
    import_->Enable(idle);
    GetMenuBar()->Enable(wxID_ADD, idle);
    remove_->Enable(idle && !selected.empty());
}
void MainView::Tick(wxTimerEvent &) {
    const auto next = context_.profiles.Snapshot();
    if (next.revision != snapshot_.revision) {
        snapshot_ = next;
        Render();
        // Background observation can recover on the next poll. Keep its error
        // inline; reserve modal alerts for failed actions or local loading.
        if (!snapshot_.error.empty() && !snapshot_.busy) {
            // Pause polling while the alert runs its nested event loop.
            timer_.Stop();
            const bool importing = !snapshot_.error.empty() && snapshot_.errorContext == AppErrorContext::import;
            // FIXME: ### Map typed failure reasons to localized recovery guidance without exposing raw native errors or secrets.
            const auto message = Localized(importing ? StringKey::ErrorsAppImportGeneric :
                snapshot_.errorContext == AppErrorContext::tunnel ? StringKey::ErrorsAppTunnel : StringKey::ErrorsAppOther);
            wxMessageDialog dialog(this, message,
                importing ? Localized(StringKey::ViewsAppToolbarImportFile) : wxTheApp->GetAppName(), wxOK | wxICON_ERROR);
            dialog.SetOKLabel(Localized(StringKey::GlobalNounsOk));
            dialog.ShowModal();
            context_.profiles.ClearError();
            timer_.Start(200);
        }
    }
    if (!snapshot_.busy && snapshot_.loaded && !pendingFiles_.empty()) {
        auto files = std::move(pendingFiles_);
        pendingFiles_.clear();
        context_.profiles.Import(std::move(files));
    } else if (++ticks_ % 10 == 0) {
        context_.tunnel.Refresh();
    }
}
void MainView::Import() {
    if (context_.profiles.Snapshot().busy) return;
    wxFileDialog dialog(this, Localized(StringKey::ViewsAppToolbarImportFile), "", "",
        wxFileSelectorDefaultWildcardStr,
        wxFD_OPEN | wxFD_FILE_MUST_EXIST | wxFD_MULTIPLE);
    if (dialog.ShowModal() != wxID_OK) return;
    wxArrayString paths;
    dialog.GetPaths(paths);
    for (const auto &path : paths) pendingFiles_.push_back(FilePath(path));
}
void MainView::Remove() {
    const auto ids = SelectedIds();
    if (ids.empty() || context_.profiles.Snapshot().busy) return;
    wxMessageDialog dialog(this, Localized(StringKey::ThemeConfirmationMessage),
        Localized(StringKey::GlobalActionsRemove), wxOK | wxCANCEL | wxCANCEL_DEFAULT | wxICON_WARNING);
    dialog.SetOKCancelLabels(Localized(StringKey::ThemeConfirmationOk), Localized(StringKey::ThemeConfirmationCancel));
    if (dialog.ShowModal() != wxID_OK) return;
    context_.profiles.Remove(ids);
}
void MainView::ToggleProfile(wxDataViewEvent &event) {
    if (rendering_ || event.GetColumn() != ThemeProfileList::ToggleColumn) return;
    const auto row = list_->ItemToRow(event.GetItem());
    if (row < 0 || static_cast<std::size_t>(row) >= visibleIds_.size()) return;
    context_.tunnel.SetEnabled(visibleIds_[row], list_->GetToggleValue(row, ThemeProfileList::ToggleColumn));
    // Restore observed state immediately; the next snapshot supplies completion
    // or failure instead of displaying an optimistic connection as successful.
    snapshot_.busy = context_.profiles.Snapshot().busy;
    Render();
}
void MainView::DisconnectActive() {
    const auto state = context_.tunnel.Snapshot();
    if (state.busy || !state.tunnelAvailable) return;
    for (const auto &tunnel : state.tunnels) {
        if (tunnel.status.value != Status::disconnected) {
            context_.tunnel.Disconnect(tunnel.id);
            return;
        }
    }
}
void MainView::ShowWindow() {
    Show();
    Iconize(false);
    Raise();
}
void MainView::Quit() {
    quitting_ = true;
    Close();
}
void MainView::CloseWindow(wxCloseEvent &event) {
    if (tray_ && !quitting_ && event.CanVeto()) {
        Hide();
        event.Veto();
        return;
    }
    event.Skip();
}
