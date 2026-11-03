// SPDX-License-Identifier: GPL-3.0
#include "app.h"
#include "partout.h"
#include <wx/artprov.h>
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
        case Status::disconnected: return _(L"Disconnected");
        case Status::connecting: return _(L"Connecting…");
        case Status::connected: return _(L"Connected");
        case Status::disconnecting: return _(L"Disconnecting…");
        default: return _(L"Unavailable");
    }
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
        menu->Append(wxID_OPEN, _(L"Open Passepartout"));
        menu->Append(wxID_STOP, _(L"Disconnect"));
        menu->AppendSeparator();
        menu->Append(wxID_EXIT, _(L"Quit"));
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
    SetAppName("Passepartout");
    bool demo = false;
    std::vector<std::filesystem::path> files;
    for (int i = 1; i < argc; ++i) {
        const wxString arg(argv[i]);
        if (arg == "--demo") demo = true;
        else files.push_back(FilePath(arg));
    }
    // Isolate fake connections and imported test data from real application data.
    const auto directory = FilePath(wxStandardPaths::Get().GetUserLocalDataDir()) /
        (demo ? "demo-profiles" : "profiles");
    instance_ = std::make_unique<wxSingleInstanceChecker>(
        "Passepartout-" + wxGetUserId() + (demo ? "-demo" : ""));
    if (instance_->IsAnotherRunning()) {
        wxMessageBox(_(L"Passepartout is already running. Open its window to import a configuration."),
                     _(L"Passepartout"), wxOK | wxICON_INFORMATION);
        return false;
    }
    partout_init_args init{};
    init.logs_private_data = false;
    partout_init(&init);
    try {
        context_ = std::make_unique<AppContext>(directory, demo);
        auto *view = new MainView(*context_, demo, std::move(files));
        SetTopWindow(view);
        Bind(wxEVT_ACTIVATE_APP, [this](wxActivateEvent &event) {
            if (event.GetActive()) context_->tunnel.Refresh();
            event.Skip();
        });
        view->Show();
        return true;
    } catch (...) {
        wxMessageBox(_(L"Unable to open the application data directory."), _(L"Passepartout"), wxOK | wxICON_ERROR);
        return false;
    }
}
int PassepartoutApp::OnExit() {
    context_.reset();
    instance_.reset();
    return wxApp::OnExit();
}
MainView::MainView(AppContext &context, bool demo, std::vector<std::filesystem::path> files)
    : wxFrame(nullptr, wxID_ANY, demo ? _(L"Passepartout — Demo (no VPN)") : _(L"Passepartout")),
      context_(context), timer_(this), pendingFiles_(std::move(files)) {
    auto *panel = new wxPanel(this);
    Theme::Apply(panel);
    const auto gap = Theme::Spacing(panel);
    auto *layout = new wxBoxSizer(wxVERTICAL);
    search_ = new wxSearchCtrl(panel, wxID_ANY);
    search_->SetDescriptiveText(_(L"Search profiles"));
    search_->ShowCancelButton(true);
    layout->Add(search_, 0, wxEXPAND | wxALL, gap);
    list_ = ThemeList(panel);
    layout->Add(list_, 1, wxEXPAND | wxLEFT | wxRIGHT, gap);
    message_ = ThemeEmptyMessage(panel, _(L"Loading profiles…"));
    layout->Add(message_, 0, wxEXPAND | wxALL, gap);
    error_ = new wxStaticText(panel, wxID_ANY, "");
    layout->Add(error_, 0, wxEXPAND | wxLEFT | wxRIGHT, gap);
    auto *actions = new wxBoxSizer(wxHORIZONTAL);
    import_ = new wxButton(panel, wxID_ADD, _(L"Import…"));
    remove_ = new wxButton(panel, wxID_DELETE, _(L"Remove"));
    connect_ = new wxButton(panel, wxID_ANY, _(L"Connect"));
    disconnect_ = new wxButton(panel, wxID_STOP, _(L"Disconnect"));
    retry_ = new wxButton(panel, wxID_REFRESH, _(L"Retry"));
    progress_ = ThemeProgressView(panel);
    for (auto *button : {import_, remove_, connect_, disconnect_, retry_}) {
        actions->Add(button, 0, wxRIGHT, gap);
    }
    actions->AddStretchSpacer();
    actions->Add(progress_, 0, wxALIGN_CENTER_VERTICAL);
    layout->Add(actions, 0, wxEXPAND | wxALL, gap);
    panel->SetSizer(layout);
    auto *menus = new wxMenuBar;
    auto *file = new wxMenu;
    file->Append(wxID_ADD, _(L"Import…\tCtrl+O"));
    file->AppendSeparator();
    file->Append(wxID_EXIT, _(L"Quit\tCtrl+Q"));
    menus->Append(file, _(L"File"));
    auto *help = new wxMenu;
    help->Append(wxID_ABOUT, _(L"About"));
    menus->Append(help, _(L"Help"));
    SetMenuBar(menus);
    CreateStatusBar();
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        Import();
    }, wxID_ADD);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        Quit();
    }, wxID_EXIT);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        wxMessageBox(_(L"Passepartout\n") + Text(partout_version()), _(L"About Passepartout"), wxOK, this);
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
    retry_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        context_.profiles.ClearError();
        context_.profiles.Load();
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
        if (!tray_->SetIcon(icon, _(L"Passepartout"))) tray_.reset();
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
        auto status = snapshot_.tunnelAvailable ? _(L"Disconnected") : _(L"Unavailable");
        for (const auto &tunnel : snapshot_.tunnels) {
            if (snapshot_.tunnelAvailable && tunnel.id == profile.id) status = StatusText(tunnel.status.value);
        }
        list_->SetItem(row, 1, status);
        visibleIds_.push_back(profile.id);
        if (std::find(selected.begin(), selected.end(), profile.id) != selected.end())
            list_->SetItemState(row, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED);
    }
    list_->Thaw();
    message_->SetLabel(!snapshot_.loaded ?
        (snapshot_.busy ? _(L"Loading profiles…") : _(L"Unable to load profiles.")) :
        (snapshot_.profiles.empty() ? _(L"Import a configuration to get started.") : _(L"No matching profiles.")));
    message_->Show(visibleIds_.empty());
    error_->SetLabel(Text(snapshot_.error));
    error_->Wrap(std::max(200, GetClientSize().x - FromDIP(40)));
    error_->Show(!snapshot_.error.empty());
    retry_->Show(!snapshot_.error.empty());
    if (snapshot_.busy) progress_->Start();
    else progress_->Stop();
    wxString connection = snapshot_.tunnelAvailable ? _(L"Disconnected") : _(L"VPN status unavailable");
    if (snapshot_.tunnelAvailable) {
        for (const auto &tunnel : snapshot_.tunnels) {
            if (tunnel.status.value == Status::disconnected) continue;
            auto name = Text(tunnel.id);
            for (const auto &profile : snapshot_.profiles) {
                if (profile.id == tunnel.id) name = Text(profile.name);
            }
            connection = name + L" — " + StatusText(tunnel.status.value);
            break;
        }
    }
    SetStatusText(connection);
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
    remove_->Enable(idle && snapshot_.tunnelAvailable && !selected.empty());
    connect_->Enable(idle && snapshot_.tunnelAvailable && selected.size() == 1 && !active);
    disconnect_->Enable(!snapshot_.busy && active);
    retry_->Enable(!snapshot_.busy);
}
void MainView::Tick(wxTimerEvent &) {
    const auto next = context_.profiles.Snapshot();
    if (next.revision != snapshot_.revision) {
        snapshot_ = next;
        Render();
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
    wxFileDialog dialog(this, _(L"Import configuration"), "", "",
        _(L"VPN configurations (*.ovpn;*.conf;*.json)|*.ovpn;*.conf;*.json|All files|*.*"),
        wxFD_OPEN | wxFD_FILE_MUST_EXIST | wxFD_MULTIPLE);
    if (dialog.ShowModal() != wxID_OK) return;
    wxArrayString paths;
    dialog.GetPaths(paths);
    for (const auto &path : paths) pendingFiles_.push_back(FilePath(path));
}
void MainView::Remove() {
    const auto ids = SelectedIds();
    if (ids.empty() || context_.profiles.Snapshot().busy) return;
    if (wxMessageBox(_(L"Remove the selected profiles? Active connections will be disconnected."),
                     _(L"Remove profiles"), wxYES_NO | wxNO_DEFAULT | wxICON_QUESTION, this) != wxYES) return;
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
    if (context_.profiles.Snapshot().busy) {
        wxMessageBox(_(L"Wait for the current operation to finish before quitting."), _(L"Passepartout"), wxOK, this);
        return;
    }
    const auto state = context_.tunnel.Snapshot();
    const bool active = std::any_of(state.tunnels.begin(), state.tunnels.end(), [](const auto &t) {
        return t.status.value != Status::disconnected;
    });
    if (active && wxMessageBox(_(L"Quit Passepartout? The VPN will remain connected."),
                               _(L"Quit"), wxYES_NO | wxNO_DEFAULT, this) != wxYES) return;
    quitting_ = true;
    Close();
}
void MainView::CloseWindow(wxCloseEvent &event) {
    if (tray_ && !quitting_ && event.CanVeto()) {
        Hide();
        event.Veto();
        return;
    }
    if (context_.profiles.Snapshot().busy && event.CanVeto()) {
        event.Veto();
        return;
    }
    event.Skip();
}
