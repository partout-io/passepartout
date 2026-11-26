// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "MainView.h"
#include "../alerts/InteractiveLoginView.h"
#include "../../strings/Strings.h"
#include "../profile/ProfileCoordinator.h"
#include "../settings/SettingsCoordinator.h"
#include <wx/stockitem.h>
#include "../settings/VersionView.h"
#include "../../strings/Unlocalized.h"
#include "../theme/ThemeModal.h"
#include "../settings/ChangelogView.h"

namespace {
wxString Text(const std::string &value) {
    return wxString::FromUTF8(value);
}

wxString QuitTitle() {
    return wxGetStockLabel(wxID_EXIT) + "\tCtrl+Q";
}
}

using namespace Passepartout;

MainView::MainView(AppContext &context, bool demo,
                   ConfigurationPickerFactory picker_factory
)
    : MainFrame(nullptr, wxID_ANY, Text(context.cross_constants.app.name) +
          (demo ? " (" + Text(context.cross_constants.command_line.demo_argument) + ")" : wxString())),
      context_(context), tunnel_timer_(this), picker_timer_(this), picker_(picker_factory(*this)), observer_([this] { UpdateState(); }) {
    Theme::Apply(this);
    auto *panel = new wxPanel(this);
    Theme::Apply(panel);
    const auto gap = Theme::Spacing(panel);
    auto *layout = new wxBoxSizer(wxVERTICAL);
    collection_ = new ProfileListView(panel, context.profiles, context.tunnel,
        [this] {
            UpdateActions();
        },
        [this](std::vector<std::string> ids) {
            Remove(std::move(ids));
        },
        [this](std::string id) {
            Edit(id);
        },
        [this](InteractiveLogin login) {
            PresentInteractiveLogin(std::move(login));
        });
    layout->Add(collection_, 1, wxEXPAND | wxLEFT | wxRIGHT | wxTOP, gap);
    message_ = Theme::EmptyMessage(panel, Localized(StringKey::GlobalNounsLoading));
    layout->Add(message_, 0, wxEXPAND | wxALL, gap);
    auto *actions = new wxBoxSizer(wxHORIZONTAL);
    import_ = new wxButton(panel, wxID_ADD, Localized(StringKey::ViewsAppToolbarImportFile));
    remove_ = new wxButton(panel, wxID_DELETE, Localized(StringKey::GlobalActionsRemove));
    progress_ = Theme::ProgressView(panel);
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
    file->Append(wxID_PREFERENCES, Localized(StringKey::ViewsSettingsTitle) + "\tCtrl+,");
    file->AppendSeparator();
    file->Append(wxID_EXIT, QuitTitle());
    menus->Append(file, wxGetStockLabel(wxID_FILE));
    auto *help = new wxMenu;
    help->Append(wxID_ABOUT, Localized(StringKey::GlobalNounsAbout));
    menus->Append(help, wxGetStockLabel(wxID_HELP));
    const auto changelog_id = wxWindow::NewControlId();
    help->Append(changelog_id, Strings::Unlocalized::Changelog);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        ThemeModal modal(this, Strings::Unlocalized::Changelog, [this](wxWindow *parent) {
            return new ChangelogView(parent, context_.version, context_.cross_constants.app, context_.constants.github);
        });
        modal.ShowModal();
    }, changelog_id);
    SetMenuBar(menus);
    ConfigureSystemMenu(
        Localized(StringKey::GlobalNounsAbout) + " " + Text(context.cross_constants.app.name) + "..."
    );
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        Import();
    }, wxID_ADD);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        Quit();
    }, wxID_EXIT);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        ThemeModal dialog(this, Localized(StringKey::GlobalNounsAbout) + " " + Text(context_.cross_constants.app.name),
            [this](wxWindow *parent) {
                const SettingsPresentation present = [parent](auto title, auto make_content) {
                    ThemeModal modal(parent, title, make_content);
                    modal.ShowModal();
                };
                return new VersionView(parent, context_.version, context_.cross_constants.app, context_.constants.github, present);
            }, ThemeModal::Mode::ReadOnly, ThemeModal::Sizing::FixedContent);
        dialog.ShowModal();
    }, wxID_ABOUT);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        SettingsCoordinator dialog(this, context_);
        dialog.ShowModal();
    }, wxID_PREFERENCES);
    import_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        Import();
    });
    remove_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        Remove(collection_->SelectedIds());
    });
    Bind(wxEVT_CHAR_HOOK, [this](wxKeyEvent &event) {
        if (!collection_->HasCollectionFocus()) {
            event.Skip();
            return;
        }
        if (event.GetKeyCode() == WXK_DELETE && !event.HasAnyModifiers()) {
            Remove(collection_->SelectedIds());
        } else if ((event.GetKeyCode() == WXK_F10 && event.ShiftDown()) ||
                   event.GetKeyCode() == WXK_WINDOWS_MENU) {
            collection_->ShowContextMenu(wxDefaultPosition);
        } else {
            event.Skip();
        }
    });
    Bind(wxEVT_TIMER, [this](wxTimerEvent &) {
        context_.tunnel.Refresh();
    }, tunnel_timer_.GetId());
    Bind(wxEVT_TIMER, &MainView::PollPicker, this, picker_timer_.GetId());
    const auto icon = Theme::AppIcon(this);
    if (icon.IsOk()) SetIcon(icon);
    SetMinSize(FromDIP(wxSize(640, 360)));
    SetSize(FromDIP(wxSize(720, 480)));
    Centre();
    observer_.Observe(context_.profiles.changes);
    observer_.Observe(context_.tunnel.changes);
    profiles_ = context_.profiles.Snapshot();
    tunnels_ = context_.tunnel.Snapshot();
    Render();
    tunnel_timer_.Start(2000);
}

MainView::~MainView() {
    observer_.Stop();
    picker_->Cancel();
    picker_timer_.Stop();
    tunnel_timer_.Stop();
}

void MainView::Render() {
    collection_->Render(profiles_, tunnels_, picking_);
    const bool tunnel_unavailable = profiles_.loaded && !tunnels_.available;
    message_->SetLabel(Localized(tunnel_unavailable ? StringKey::ErrorsAppTunnel : StringKey::ViewsAppFoldersNoProfiles));
    message_->Show(tunnel_unavailable || (profiles_.loaded && profiles_.profiles.empty()));
    const bool activity = profiles_.busy || tunnels_.HasActivity();
    if (activity) progress_->Start();
    else progress_->Stop();
    progress_->Show(activity);
    UpdateActions();
    GetChildren().GetFirst()->GetData()->Layout();
}

void MainView::UpdateActions() {
    const bool idle = !picking_ && !profiles_.busy && !tunnels_.busy && !tunnels_.pending_profile && profiles_.loaded;
    const auto selected = collection_->SelectedIds();
    import_->Enable(idle);
    GetMenuBar()->Enable(wxID_ADD, idle);
    remove_->Enable(!picking_ && ProfileObservable::CanRemove(profiles_, selected) && !tunnels_.pending_profile);
}

void MainView::PollPicker(wxTimerEvent &) {
    if (auto result = picker_->Poll()) {
        picker_timer_.Stop();
        picking_ = false;
        if (result->failed) context_.profiles.ImportFailed();
        else if (result->files) context_.profiles.ImportFiles(std::move(result->files));
        UpdateState();
    }
}

void MainView::UpdateState() {
    if (presenting_) return;
    profiles_ = context_.profiles.Snapshot();
    tunnels_ = context_.tunnel.Snapshot();
    Render();
    PresentOperationError();
    ProcessActivations();
}

void MainView::PresentOperationError() {
    // Background observation can recover on the next poll. Keep its error
    // inline; reserve modal alerts for failed actions or local loading.
    if ((profiles_.operation_error.has_value() || tunnels_.errors.operation) && !profiles_.busy && !tunnels_.busy) {
        // Defer state handling while the alert runs its nested event loop.
        presenting_ = true;
        tunnel_timer_.Stop();
        const bool profile_error = profiles_.operation_error.has_value();
        const bool importing = profile_error && profiles_.operation_error == ProfileObservable::OperationErrorContext::import;
        // FIXME: ### Map typed failure reasons to localized recovery guidance without exposing raw native errors or secrets.
        const auto message = Localized(importing ? StringKey::ErrorsAppImportGeneric :
            !profile_error ? StringKey::ErrorsAppTunnel : StringKey::ErrorsAppOther);
        wxMessageDialog dialog(this, message,
            importing ? Localized(StringKey::ViewsAppToolbarImportFile) : wxTheApp->GetAppName(), wxOK | wxICON_ERROR);
        dialog.SetOKLabel(Localized(StringKey::GlobalNounsOk));
        dialog.ShowModal();
        if (profile_error) context_.profiles.ClearOperationError();
        else context_.tunnel.ClearOperationError();
        presenting_ = false;
        tunnel_timer_.Start(2000);
    }
}

void MainView::ProcessActivations() {
    if (presenting_) return;
    if (!picking_ && !profiles_.busy && !tunnels_.busy && profiles_.loaded && !activations_.empty()) {
        auto files = std::move(activations_.front());
        activations_.pop_front();
        context_.profiles.ImportFiles(std::move(files));
    }
}

void MainView::PresentInteractiveLogin(InteractiveLogin login) {
    presenting_ = true;
    tunnel_timer_.Stop();
    ThemeModal modal(this, Text(login.original.name), [&login](wxWindow *parent) {
        return new InteractiveLoginView(parent, login);
    }, ThemeModal::Mode::Editable, ThemeModal::Sizing::Content,
        [&login] { return login.CanSubmit(); });
    auto *connect = wxDynamicCast(modal.FindWindow(wxID_OK), wxButton);
    connect->SetLabel(Localized(StringKey::GlobalActionsConnect));
    const auto result = modal.ShowModal();
    if (result == wxID_OK && login.CanSubmit())
        context_.tunnel.Connect(std::move(login.original), std::move(login.credentials));
    presenting_ = false;
    tunnel_timer_.Start(2000);
    UpdateState();
}

void MainView::Import() {
    if (picking_ || context_.profiles.Snapshot().busy) return;
    picking_ = true;
    Render();
    try {
        picker_->Start();
        picker_timer_.Start(200);
    } catch (...) {
        picking_ = false;
        picker_->Cancel();
        context_.profiles.ImportFailed();
        Render();
    }
}

void MainView::Remove(std::vector<std::string> ids) {
    if (picking_ || !ProfileObservable::CanRemove(context_.profiles.Snapshot(), ids) || context_.tunnel.Snapshot().pending_profile) return;
    wxMessageDialog dialog(this, Localized(StringKey::ThemeConfirmationMessage),
        Localized(StringKey::GlobalActionsRemove), wxOK | wxCANCEL | wxCANCEL_DEFAULT | wxICON_WARNING);
    dialog.SetOKCancelLabels(Localized(StringKey::ThemeConfirmationOk), Localized(StringKey::ThemeConfirmationCancel));
    if (dialog.ShowModal() != wxID_OK) return;
    context_.profiles.Remove(ids);
}

void MainView::Quit() {
    Close();
}

void MainView::Activate(std::shared_ptr<const ConfigurationFiles> files) {
    if (files && (files->Count() || files->SelectionFailures())) activations_.push_back(std::move(files));
    UpdateState();
    if (IsIconized()) Iconize(false);
    Raise();
}

void MainView::Edit(const std::string &id) {
    if (picking_ || context_.profiles.Snapshot().busy) return;
    const auto editor = context_.profiles.CreateEditor(id);
    if (!editor) return;
    ProfileCoordinator dialog(this, context_.profiles, editor, *context_.wireguard_keygen);
    dialog.ShowModal();
}
