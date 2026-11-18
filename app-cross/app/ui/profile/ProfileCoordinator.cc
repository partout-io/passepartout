// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileCoordinator.h"
#include "ProfileView.h"
#include "ProfileModuleList.h"
#include "OpenVPNView.h"
#include "OpenVPNCredentialsView.h"
#include "OpenVPNRemotesView.h"
#include "DNSView.h"
#include "HTTPProxyView.h"
#include "IPView.h"
#include "WireGuardView.h"
#include "../LongContentView.h"
#include "../Presentation.h"
#include "../extensions/Module.h"
#include <algorithm>
#include <type_traits>
#include <wx/display.h>
#include <wx/wupdlock.h>
#include "../../theme/ThemeSplitView.h"
#include "../../theme/ThemeModal.h"

namespace Passepartout {
ProfileCoordinator::ProfileCoordinator(wxWindow *parent, ProfileObservable &profiles,
    std::shared_ptr<ProfileEditor> editor, const WireGuardKeyGenerator &keys)
    : wxDialog(parent, wxID_ANY, Localized(StringKey::GlobalNounsProfile), wxDefaultPosition,
        wxDefaultSize, wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER),
      profiles_(profiles), editor_(std::move(editor)), keys_(keys), timer_(this) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    auto *splitter = new ThemeSplitView(this);
    auto *sidebarPanel = splitter->Sidebar();
    auto *detailPanel = splitter->Detail();
    pages_ = new wxSimplebook(detailPanel);
    pages_->SetFitToCurrentPage(true);
    auto *buttons = new wxBoxSizer(wxHORIZONTAL);
    progress_ = ThemeProgressView(this);
    progress_->Hide();
    save_ = new wxButton(this, wxID_SAVE, Localized(StringKey::GlobalActionsSave));
    cancel_ = new wxButton(this, wxID_CANCEL, Localized(StringKey::GlobalActionsCancel));
    auto *sidebar = new wxBoxSizer(wxVERTICAL);
    modules_ = new ProfileModuleList(sidebarPanel, *editor_, [this](std::size_t selection) {
        SelectSection(selection);
    });
    sidebar->Add(modules_, 1, wxEXPAND | wxALL, Theme::Spacing(this));
    sidebarPanel->SetSizer(sidebar);
    auto *detail = new wxBoxSizer(wxVERTICAL);
    heading_ = new wxStaticText(detailPanel, wxID_ANY, {});
    heading_->SetFont(heading_->GetFont().Bold());
    detail->Add(heading_, 0, wxEXPAND | wxALL, Theme::Spacing(this));
    detail->Add(pages_, 1, wxEXPAND);
    detailPanel->SetSizer(detail);
    const int sidebarWidth = splitter->InitializePanes();
    layout->Add(splitter, 1, wxEXPAND);
    buttons->Add(progress_, 0, wxLEFT | wxALIGN_CENTER_VERTICAL, Theme::Spacing(this));
    buttons->AddStretchSpacer();
    auto *actions = new wxStdDialogButtonSizer;
    actions->SetAffirmativeButton(save_);
    actions->SetCancelButton(cancel_);
    actions->Realize();
    buttons->Add(actions);
    SetAffirmativeId(wxID_SAVE);
    layout->Add(buttons, 0, wxEXPAND | wxALL, Theme::Spacing(this));
    SetSizer(layout);
    cancel_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        Dismiss();
    });
    save_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        profiles_.SaveEditor(editor_);
        RefreshState();
    });
    Bind(wxEVT_CLOSE_WINDOW, [this](wxCloseEvent &event) {
        if (editor_->Snapshot().saving) {
            if (event.CanVeto()) event.Veto();
            return;
        }
        EndModal(wxID_CANCEL);
    });
    Bind(wxEVT_CHAR_HOOK, [this](wxKeyEvent &event) {
        if (event.GetKeyCode() == WXK_ESCAPE) Dismiss();
        else event.Skip();
    });
    Bind(wxEVT_TIMER, [this](wxTimerEvent &) {
        RefreshState();
    });
    ShowSection(new ProfileView(pages_, editor_, [this] {
        RefreshState();
    }), Localized(StringKey::GlobalNounsGeneral));
    RefreshState();
    GetSizer()->SetSizeHints(this);
    // Choose one reading area at creation; navigation preserves manual resizing.
    const wxSize viewport(GetCharWidth() * 90, GetCharHeight() * 28);
    auto size = GetSize() - pages_->GetClientSize() + viewport;
    size.IncTo(GetBestSize());
    const auto workArea = wxDisplay(this).GetClientArea();
    size.DecTo(workArea.GetSize());
    SetSize(size);
    splitter->SetSashPosition(sidebarWidth);
    timer_.Start(100);
    CentreOnParent();
    auto position = GetPosition();
    position.x = std::max(workArea.x, std::min(position.x, workArea.GetRight() - GetSize().x + 1));
    position.y = std::max(workArea.y, std::min(position.y, workArea.GetBottom() - GetSize().y + 1));
    Move(position);
}
void ProfileCoordinator::ShowSection(wxWindow *page, const wxString &title) {
    wxWindowUpdateLocker update(this);
    pages_->AddPage(page, title, true);
    heading_->SetLabel(title);
    pages_->InvalidateBestSize();
    InvalidateBestSize();
    Layout();
}
void ProfileCoordinator::Dismiss() {
    if (!editor_->Snapshot().saving) EndModal(wxID_CANCEL);
}
void ProfileCoordinator::SelectSection(std::size_t selection) {
    if (editor_->Snapshot().saving || selection == selection_) return;
    wxWindowUpdateLocker update(this);
    selection_ = selection;
    pages_->DeleteAllPages();
    if (selection == 0) {
        ShowSection(new ProfileView(pages_, editor_, [this] {
            RefreshState();
        }), Localized(StringKey::GlobalNounsGeneral));
    } else {
        OpenModule(selection - 1);
    }
}
void ProfileCoordinator::OpenModule(std::size_t index) {
    const auto module = editor_->Snapshot().draft.modules.at(index);
    const auto openContent = [this](wxString title, wxString content) {
        ThemeModal modal(this, title, [title, content](wxWindow *parent) {
            return new LongContentView(parent, title, content);
        });
        modal.ShowModal();
    };
    wxWindow *page = std::visit([&](const auto &tagged) -> wxWindow * {
        using namespace Partout::Models;
        using Tag = std::decay_t<decltype(tagged)>;
        if constexpr (std::is_same_v<Tag, TaggedModuleDns>) return new DNSView(pages_, tagged.value, openContent);
        else if constexpr (std::is_same_v<Tag, TaggedModuleHTTPProxy>) return new HTTPProxyView(pages_, tagged.value, openContent);
        else if constexpr (std::is_same_v<Tag, TaggedModuleIp>) return new IPView(pages_, tagged.value, openContent);
        else if constexpr (std::is_same_v<Tag, TaggedModuleWireGuard>) return new WireGuardView(pages_, tagged.value, openContent, keys_);
        else if constexpr (std::is_same_v<Tag, TaggedModuleOpenVpn>) {
            return new OpenVPNView(pages_, tagged.value, openContent, [this, index] {
                const auto module = std::get<TaggedModuleOpenVpn>(editor_->Snapshot().draft.modules.at(index));
                OpenVpnCredentials credentials{};
                credentials.otpMethod.value = OpenVpnCredentialsOTPMethod::none;
                if (module.value.credentials) credentials = *module.value.credentials;
                const auto update = [this, index](std::string username, std::string password) {
                    auto module = std::get<TaggedModuleOpenVpn>(editor_->Snapshot().draft.modules.at(index));
                    OpenVpnCredentials credentials{};
                    credentials.otpMethod.value = OpenVpnCredentialsOTPMethod::none;
                    if (module.value.credentials) credentials = *module.value.credentials;
                    credentials.username = std::move(username);
                    credentials.password = std::move(password);
                    module.value.credentials = std::move(credentials);
                    editor_->UpdateModule(module);
                    RefreshState();
                };
                ThemeModal modal(this, Localized(StringKey::GlobalNounsAccount),
                    [credentials, update](wxWindow *parent) {
                        return new OpenVPNCredentialsView(parent, credentials, update);
                    });
                modal.ShowModal();
            }, [this, index] {
                const auto draft = editor_->Snapshot().draft;
                const auto &module = std::get<TaggedModuleOpenVpn>(draft.modules.at(index)).value;
                if (!module.configuration || !module.configuration->remotes) return;
                ThemeModal modal(this, Localized(StringKey::ModulesOpenvpnRemotes),
                    [&module](wxWindow *parent) {
                        return new OpenVPNRemotesView(parent, *module.configuration->remotes);
                    });
                modal.ShowModal();
            });
        } else {
            return new ThemeDetailView(pages_);
        }
    }, module);
    ShowSection(page, ModuleTitle(module));
}
void ProfileCoordinator::RefreshState() {
    const auto state = editor_->Snapshot();
    if (state.saved) {
        timer_.Stop();
        EndModal(wxID_SAVE);
        return;
    }
    pages_->Enable(!state.saving);
    modules_->Enable(!state.saving);
    if (state.saving) progress_->Start();
    else progress_->Stop();
    if (progress_->Show(state.saving)) Layout();
    cancel_->Enable(!state.saving);
    save_->Enable(editor_->CanSave() && ProfileObservable::CanSave(profiles_.Snapshot(), state.draft.id));
    if (state.failed) {
        editor_->ClearError();
        PresentError(this);
    }
}
}
