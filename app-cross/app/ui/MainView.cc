// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "MainView.h"
#include "../strings/Strings.h"
#include "profile/ProfileCoordinator.h"
#include "settings/SettingsCoordinator.h"
#include <wx/stockitem.h>
#include <wx/aboutdlg.h>
#include "../strings/Unlocalized.h"
#include "../theme/ThemeModal.h"
#include "../theme/ThemeLongContent.h"
#ifdef __WXMSW__
#include <windows.h>
#endif

using namespace Passepartout;
namespace {
#ifdef __WXMSW__
constexpr unsigned SystemAbout = 0x100;
#endif
wxString Text(const std::string &value) {
    return wxString::FromUTF8(value);
}
wxString QuitTitle() {
    return wxGetStockLabel(wxID_EXIT) + "\tCtrl+Q";
}
}

MainView::MainView(AppContext &context, bool demo,
                   ConfigurationPickerFactory pickerFactory)
    : wxFrame(nullptr, wxID_ANY, Text(context.crossConstants.tags.app) +
          (demo ? " (" + Text(context.crossConstants.commandLine.demoArgument) + ")" : wxString())),
      context_(context), timer_(this), picker_(pickerFactory(*this)) {
    auto *panel = new wxPanel(this);
    Theme::Apply(panel);
    const auto gap = Theme::Spacing(panel);
    auto *layout = new wxBoxSizer(wxVERTICAL);
    collection_ = new ProfileCollectionView(panel, context.tunnel,
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
    file->Append(wxID_PREFERENCES, Localized(StringKey::ViewsSettingsTitle) + "\tCtrl+,");
    file->AppendSeparator();
    file->Append(wxID_EXIT, QuitTitle());
    menus->Append(file, wxGetStockLabel(wxID_FILE));
    auto *help = new wxMenu;
    help->Append(wxID_ABOUT, Localized(StringKey::GlobalNounsAbout));
    menus->Append(help, wxGetStockLabel(wxID_HELP));
    const auto changelogId = wxWindow::NewControlId();
    help->Append(changelogId, Strings::Unlocalized::Changelog);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        const auto content = Text(context_.version.Snapshot().changelog);
        ThemeModal modal(this, Strings::Unlocalized::Changelog, [content](wxWindow *parent) {
            return new ThemeLongContent(parent, Strings::Unlocalized::Changelog, content);
        });
        modal.ShowModal();
    }, changelogId);
    SetMenuBar(menus);
#ifdef __WXMSW__
    if (auto menu = GetSystemMenu(static_cast<HWND>(GetHandle()), FALSE)) {
        const auto title = Localized(StringKey::GlobalNounsAbout) + " " +
            Text(context.crossConstants.tags.app) + "...";
        InsertMenuW(menu, 0, MF_BYPOSITION | MF_SEPARATOR, 0, nullptr);
        InsertMenuW(menu, 0, MF_BYPOSITION | MF_STRING, SystemAbout, title.wc_str());
    }
#endif
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        Import();
    }, wxID_ADD);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        Quit();
    }, wxID_EXIT);
    Bind(wxEVT_MENU, [this](wxCommandEvent &) {
        wxAboutDialogInfo info;
        info.SetName(Text(context_.crossConstants.tags.app));
        info.SetVersion(Text(context_.version.Snapshot().current));
        info.SetIcon(Theme::AppIcon(this, 64));
        info.AddDeveloper(Strings::Unlocalized::AuthorName);
        wxAboutBox(info, this);
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
    Bind(wxEVT_SYS_COLOUR_CHANGED, [panel](wxSysColourChangedEvent &event) {
        Theme::Apply(panel);
        event.Skip();
    });
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
    collection_->Render(snapshot_, picking_);
    const bool idle = !picking_ && !snapshot_.foregroundBusy && !snapshot_.pendingProfile && snapshot_.loaded;
    const auto selected = collection_->SelectedIds();
    import_->Enable(idle);
    GetMenuBar()->Enable(wxID_ADD, idle);
    remove_->Enable(!picking_ && ProfileObservable::CanRemove(snapshot_, selected));
}
void MainView::Tick(wxTimerEvent &) {
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
    if (!picking_ && !snapshot_.busy && snapshot_.loaded && !activations_.empty()) {
        auto files = std::move(activations_.front());
        activations_.pop_front();
        context_.profiles.ImportFiles(std::move(files));
    } else if (++ticks_ % 10 == 0) {
        context_.tunnel.Refresh();
    }
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
    if (files && (files->Count() || files->selectionFailures)) activations_.push_back(std::move(files));
    if (IsIconized()) Iconize(false);
    Raise();
}
void MainView::Edit(const std::string &id) {
    if (picking_ || context_.profiles.Snapshot().foregroundBusy) return;
    const auto editor = context_.profiles.CreateEditor(id);
    if (!editor) return;
    ProfileCoordinator dialog(this, context_.profiles, editor, *context_.wireGuardKeys);
    dialog.ShowModal();
}

#ifdef __WXMSW__
WXLRESULT MainView::MSWWindowProc(WXUINT message, WXWPARAM wParam, WXLPARAM lParam) {
    if (message == WM_SYSCOMMAND && (wParam & 0xfff0) == SystemAbout) {
        // Dispatch through the existing About action after native menu handling.
        auto *event = new wxCommandEvent(wxEVT_MENU, wxID_ABOUT);
        wxQueueEvent(this, event);
        return 0;
    }
    return wxFrame::MSWWindowProc(message, wParam, lParam);
}
#endif
