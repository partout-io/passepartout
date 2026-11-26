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
#include "../theme/ThemeLongContent.h"

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
                   Configuration::PickerFactory picker_factory
)
    : MainFrame(nullptr, wxID_ANY, Text(context.cross_constants.tags.app) +
          (demo ? " (" + Text(context.cross_constants.command_line.demo_argument) + ")" : wxString())),
      context_(context), timer_(this), picker_(picker_factory(*this)) {
    Theme::Apply(this);
    auto *panel = new wxPanel(this);
    Theme::Apply(panel);
    const auto gap = Theme::Spacing(panel);
    auto *layout = new wxBoxSizer(wxVERTICAL);
    collection_ = new ProfileListView(panel, context.tunnel,
        [this] {
            UpdateActions();
        },
        [this](std::vector<std::string> ids) {
            Remove(std::move(ids));
        },
        [this](std::string id) {
            Edit(id);
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
        const auto content = Text(context_.version.Snapshot().changelog);
        ThemeModal modal(this, Strings::Unlocalized::Changelog, [content](wxWindow *parent) {
            return new ThemeLongContent(parent, Strings::Unlocalized::Changelog, content);
        });
        modal.ShowModal();
    }, changelog_id);
    SetMenuBar(menus);
    ConfigureSystemMenu(
        Localized(StringKey::GlobalNounsAbout) + " " + Text(context.cross_constants.tags.app) + "..."
    );
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        Import();
    }, wxID_ADD);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        Quit();
    }, wxID_EXIT);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        ThemeModal dialog(this, Localized(StringKey::GlobalNounsAbout) + " " + Text(context_.cross_constants.tags.app),
            [this](wxWindow *parent) {
                const SettingsPresentation present = [parent](auto title, auto make_content) {
                    ThemeModal modal(parent, title, make_content);
                    modal.ShowModal();
                };
                return new VersionView(parent, context_.version, Text(context_.cross_constants.tags.app), present);
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
    Bind(wxEVT_TIMER, &MainView::Tick, this);
    const auto icon = Theme::AppIcon(this);
    if (icon.IsOk()) SetIcon(icon);
    SetMinSize(FromDIP(wxSize(640, 360)));
    SetSize(FromDIP(wxSize(720, 480)));
    Centre();
    snapshot_ = context_.profiles.Snapshot();
    Render();
    timer_.Start(200);
}

MainView::~MainView() {
    picker_->Cancel();
    timer_.Stop();
}

void MainView::Render() {
    const bool tunnel_unavailable = !snapshot_.tunnel_error.empty() || !snapshot_.reconciliation_error.empty();
    message_->SetLabel(Localized(tunnel_unavailable ? StringKey::ErrorsAppTunnel : StringKey::ViewsAppFoldersNoProfiles));
    message_->Show(tunnel_unavailable || (snapshot_.loaded && snapshot_.profiles.empty()));
    const bool activity = snapshot_.HasActivity();
    if (activity) progress_->Start();
    else progress_->Stop();
    progress_->Show(activity);
    UpdateActions();
    GetChildren().GetFirst()->GetData()->Layout();
}

void MainView::UpdateActions() {
    collection_->Render(snapshot_, picking_);
    const bool idle = !picking_ && !snapshot_.foreground_busy && !snapshot_.pending_profile && snapshot_.loaded;
    const auto selected = collection_->SelectedIds();
    import_->Enable(idle);
    GetMenuBar()->Enable(wxID_ADD, idle);
    remove_->Enable(!picking_ && ProfileObservable::CanRemove(snapshot_, selected));
}

void MainView::Tick(wxTimerEvent &) {
    PresentInteractiveLogin();
    if (picking_) {
        if (auto result = picker_->Poll()) {
            picking_ = false;
            if (result->failed) context_.profiles.ImportFailed();
            else if (result->files) context_.profiles.ImportFiles(std::move(result->files));
            UpdateActions();
        }
    }
    const auto next = context_.profiles.Snapshot();
    if (next.revision != snapshot_.revision) {
        snapshot_ = next;
        Render();
        // Background observation can recover on the next poll. Keep its error
        // inline; reserve modal alerts for failed actions or local loading.
        if (!snapshot_.error.empty() && !snapshot_.busy) {
            // Pause polling while the alert runs its nested event loop.
            timer_.Stop();
            const bool importing = !snapshot_.error.empty() && snapshot_.error_context == AppErrorContext::import;
            // FIXME: ### Map typed failure reasons to localized recovery guidance without exposing raw native errors or secrets.
            const auto message = Localized(importing ? StringKey::ErrorsAppImportGeneric :
                snapshot_.error_context == AppErrorContext::tunnel ? StringKey::ErrorsAppTunnel : StringKey::ErrorsAppOther);
            wxMessageDialog dialog(this, message,
                importing ? Localized(StringKey::ViewsAppToolbarImportFile) : wxTheApp->GetAppName(), wxOK | wxICON_ERROR);
            dialog.SetOKLabel(Localized(StringKey::GlobalNounsOk));
            dialog.ShowModal();
            context_.profiles.ClearError();
            timer_.Start(200);
        }
    }
    if (!picking_ && !snapshot_.busy && snapshot_.loaded && !activations_.empty()) {
        auto files = std::move(activations_.front());
        activations_.pop_front();
        context_.profiles.ImportFiles(std::move(files));
    } else if (++ticks_ % 10 == 0) {
        context_.tunnel.Refresh();
    }
}

void MainView::PresentInteractiveLogin() {
    auto login = context_.tunnel.TakeInteractiveLogin();
    if (!login) return;
    timer_.Stop();
    ThemeModal modal(this, Text(login->original.name), [&login](wxWindow *parent) {
        return new InteractiveLoginView(parent, *login);
    }, ThemeModal::Mode::Editable, ThemeModal::Sizing::Content,
        [&login] { return login->CanSubmit(); });
    auto *connect = wxDynamicCast(modal.FindWindow(wxID_OK), wxButton);
    connect->SetLabel(Localized(StringKey::GlobalActionsConnect));
    const auto result = modal.ShowModal();
    if (result == wxID_OK) context_.tunnel.CompleteInteractiveLogin(std::move(*login));
    timer_.Start(200);
}

void MainView::Import() {
    if (picking_ || context_.profiles.Snapshot().busy) return;
    picking_ = true;
    UpdateActions();
    try {
        picker_->Start();
    } catch (...) {
        picking_ = false;
        picker_->Cancel();
        context_.profiles.ImportFailed();
        UpdateActions();
    }
}

void MainView::Remove(std::vector<std::string> ids) {
    if (picking_ || !ProfileObservable::CanRemove(context_.profiles.Snapshot(), ids)) return;
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
    if (files && (files->Count() || files->selection_failures)) activations_.push_back(std::move(files));
    if (IsIconized()) Iconize(false);
    Raise();
}

void MainView::Edit(const std::string &id) {
    if (picking_ || context_.profiles.Snapshot().foreground_busy) return;
    const auto editor = context_.profiles.CreateEditor(id);
    if (!editor) return;
    ProfileCoordinator dialog(this, context_.profiles, editor, *context_.wire_guard_keys);
    dialog.ShowModal();
}
