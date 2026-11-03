// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "app.h"
#include "strings/strings.h"
#include "partout.h"
#include <wx/artprov.h>
#include <wx/aboutdlg.h>
#include <wx/stdpaths.h>
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
wxString QuitTitle() {
    auto title = Localized(StringKey::ViewsAppMenuItemsQuit);
    title.Replace("%@", Text(defaultCrossConstants.tags.app));
    return title;
}
class Tray final : public wxTaskBarIcon {
public:
    explicit Tray(MainView &view) : view_(view) {
        Bind(wxEVT_TASKBAR_LEFT_DCLICK, [this](wxTaskBarIconEvent &) {
            view_.ShowWindow();
        });
    }
private:
    wxMenu *CreatePopupMenu() override {
        auto *menu = new wxMenu;
        menu->Append(wxID_OPEN, Localized(StringKey::GlobalActionsShow));
        menu->Append(wxID_STOP, Localized(StringKey::GlobalActionsDisconnect));
        menu->AppendSeparator();
        menu->Append(wxID_EXIT, QuitTitle());
        menu->Bind(wxEVT_MENU, [this](wxCommandEvent &) {
            view_.ShowWindow();
        }, wxID_OPEN);
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
        wxMessageBox(Localized(StringKey::ErrorsAppOther),
                     wxTheApp->GetAppName(), wxOK | wxICON_INFORMATION);
        return false;
    }
    partout_init_args init{};
    init.logs_private_data = false;
    partout_init(&init);
    try {
        context_ = std::make_unique<AppContext>(dataRoot, demo);
        auto *view = new MainView(*context_, demo, std::move(files));
        SetTopWindow(view);
        Bind(wxEVT_ACTIVATE_APP, [this](wxActivateEvent &event) {
            if (event.GetActive()) context_->tunnel.Refresh();
            event.Skip();
        });
        view->Show();
        return true;
    } catch (...) {
        wxMessageBox(Localized(StringKey::ErrorsAppOther), wxTheApp->GetAppName(), wxOK | wxICON_ERROR);
        return false;
    }
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
    list_ = ThemeList(panel);
    layout->Add(list_, 1, wxEXPAND | wxLEFT | wxRIGHT, gap);
    message_ = ThemeEmptyMessage(panel, Localized(StringKey::GlobalNounsLoading));
    layout->Add(message_, 0, wxEXPAND | wxALL, gap);
    auto *actions = new wxBoxSizer(wxHORIZONTAL);
    import_ = new wxButton(panel, wxID_ADD, Localized(StringKey::ViewsAppToolbarImportFile));
    remove_ = new wxButton(panel, wxID_DELETE, Localized(StringKey::GlobalActionsRemove));
    connect_ = new wxButton(panel, wxID_ANY, Localized(StringKey::GlobalActionsConnect));
    disconnect_ = new wxButton(panel, wxID_STOP, Localized(StringKey::GlobalActionsDisconnect));
    progress_ = ThemeProgressView(panel);
    for (auto *button : {import_, remove_, connect_, disconnect_}) {
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
    file->Append(wxID_EXIT, wxGetTranslation("E&xit"));
    menus->Append(file, wxGetTranslation("&File"));
    auto *help = new wxMenu;
    help->Append(wxID_ABOUT, Localized(StringKey::GlobalNounsAbout));
    menus->Append(help, wxGetTranslation("&Help"));
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
    connect_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        Connect();
    });
    disconnect_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        DisconnectActive();
    });
    search_->Bind(wxEVT_TEXT, [this](wxCommandEvent &) {
        Render();
    });
    list_->Bind(wxEVT_LIST_ITEM_SELECTED, [this](wxListEvent &) {
        UpdateActions();
    });
    list_->Bind(wxEVT_LIST_ITEM_DESELECTED, [this](wxListEvent &) {
        UpdateActions();
    });
    Bind(wxEVT_TIMER, &MainView::Tick, this);
    Bind(wxEVT_CLOSE_WINDOW, &MainView::CloseWindow, this);
    Bind(wxEVT_SYS_COLOUR_CHANGED, [panel](wxSysColourChangedEvent &event) {
        Theme::Apply(panel);
        event.Skip();
    });
    if (wxTaskBarIcon::IsAvailable()) {
        tray_ = std::make_unique<Tray>(*this);
        wxIcon icon;
        icon.CopyFromBitmap(wxArtProvider::GetBitmap(wxART_INFORMATION, wxART_OTHER, FromDIP(wxSize(32, 32))));
        if (!tray_->SetIcon(icon, wxTheApp->GetAppName())) tray_.reset();
    }
    SetMinSize(FromDIP(wxSize(720, 420)));
    SetSize(FromDIP(wxSize(820, 560)));
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
    long item = -1;
    while ((item = list_->GetNextItem(item, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED)) != -1) {
        if (static_cast<std::size_t>(item) < visibleIds_.size()) ids.push_back(visibleIds_[item]);
    }
    return ids;
}
void MainView::Render() {
    const auto selected = SelectedIds();
    list_->Freeze();
    list_->DeleteAllItems();
    visibleIds_.clear();
    const auto query = search_->GetValue().Lower();
    for (const auto &profile : snapshot_.profiles) {
        if (!query.empty() && !Text(profile.name).Lower().Contains(query)) continue;
        const auto row = list_->InsertItem(list_->GetItemCount(), Text(profile.name));
        auto status = snapshot_.tunnelAvailable ? Localized(StringKey::EntitiesTunnelStatusInactive) : wxString();
        for (const auto &tunnel : snapshot_.tunnels) {
            if (snapshot_.tunnelAvailable && tunnel.id == profile.id) status = StatusText(tunnel.status.value);
        }
        list_->SetItem(row, 1, status);
        visibleIds_.push_back(profile.id);
        if (std::find(selected.begin(), selected.end(), profile.id) != selected.end())
            list_->SetItemState(row, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED);
    }
    list_->Thaw();
    message_->SetLabel(Localized(StringKey::ViewsAppFoldersNoProfiles));
    message_->Show(snapshot_.loaded && snapshot_.profiles.empty());
    if (snapshot_.busy) progress_->Start();
    else progress_->Stop();
    UpdateActions();
    GetChildren().GetFirst()->GetData()->Layout();
}
void MainView::UpdateActions() {
    const bool idle = !snapshot_.busy && snapshot_.loaded;
    const auto selected = SelectedIds();
    const bool active = snapshot_.tunnelAvailable && std::any_of(snapshot_.tunnels.begin(), snapshot_.tunnels.end(), [](const auto &t) {
        return t.status.value != Status::disconnected;
    });
    import_->Enable(idle);
    GetMenuBar()->Enable(wxID_ADD, idle);
    remove_->Enable(idle && !selected.empty());
    connect_->Enable(idle && snapshot_.tunnelAvailable && selected.size() == 1 && !active);
    disconnect_->Enable(!snapshot_.busy && active);
}
void MainView::Tick(wxTimerEvent &) {
    const auto next = context_.profiles.Snapshot();
    if (next.revision != snapshot_.revision) {
        const bool newTunnelError = !next.tunnelError.empty() && next.tunnelError != snapshot_.tunnelError;
        snapshot_ = next;
        Render();
        if ((!snapshot_.error.empty() || newTunnelError) && !snapshot_.busy) {
            // Pause polling while the alert runs its nested event loop.
            timer_.Stop();
            const bool importing = !snapshot_.error.empty() && snapshot_.errorContext == AppErrorContext::import;
            const auto message = Localized(importing ? StringKey::ErrorsAppImportGeneric :
                snapshot_.error.empty() || snapshot_.errorContext == AppErrorContext::tunnel ? StringKey::ErrorsAppTunnel : StringKey::ErrorsAppOther);
            wxMessageDialog dialog(this, message,
                importing ? Localized(StringKey::ViewsAppToolbarImportFile) : wxTheApp->GetAppName(), wxOK | wxICON_ERROR);
            dialog.SetOKLabel(Localized(StringKey::GlobalNounsOk));
            dialog.ShowModal();
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
        Localized(StringKey::GlobalActionsRemove), wxOK | wxCANCEL | wxCANCEL_DEFAULT | wxICON_QUESTION);
    dialog.SetOKCancelLabels(Localized(StringKey::ThemeConfirmationOk), Localized(StringKey::ThemeConfirmationCancel));
    if (dialog.ShowModal() != wxID_OK) return;
    context_.profiles.Remove(ids);
}
void MainView::Connect() {
    const auto ids = SelectedIds();
    if (ids.size() == 1) context_.tunnel.Connect(ids.front());
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
