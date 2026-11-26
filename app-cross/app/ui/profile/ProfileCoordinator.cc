// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileCoordinator.h"
#include "ProfileView.h"
#include "ProfileModuleList.h"
#include "modules/OpenVPNView.h"
#include "modules/OpenVPNCredentialsView.h"
#include "../theme/ThemeTextList.h"
#include "modules/DNSView.h"
#include "modules/OnDemandView.h"
#include "modules/HTTPProxyView.h"
#include "modules/IPView.h"
#include "modules/WireGuardView.h"
#include "../theme/ThemeLongContent.h"
#include "../platform/Presentation.h"
#include "../extensions/ModelsExtensions.h"
#include <algorithm>
#include <type_traits>
#include <wx/display.h>
#include <wx/wupdlock.h>
#include "../theme/ThemeSplitView.h"
#include "../theme/ThemeModal.h"

namespace Passepartout {
ProfileCoordinator::ProfileCoordinator(wxWindow *parent, ProfileObservable &profiles,
    std::shared_ptr<ProfileEditor> editor, const WireGuardKeyGenerator &keys)
    : wxDialog(parent, wxID_ANY, Localized(StringKey::GlobalNounsProfile), wxDefaultPosition,
        wxDefaultSize, wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER),
      profiles_(profiles), editor_(std::move(editor)), keys_(keys), timer_(this) {
    Theme::Apply(this);
    SetIcon(Theme::ProfileIcon(this));
    Bind(wxEVT_SYS_COLOUR_CHANGED, [this](wxSysColourChangedEvent &event) {
        SetIcon(Theme::ProfileIcon(this));
        event.Skip();
    });
    Bind(wxEVT_DPI_CHANGED, [this](wxDPIChangedEvent &event) {
        SetIcon(Theme::ProfileIcon(this));
        event.Skip();
    });
    auto *layout = new wxBoxSizer(wxVERTICAL);
    auto *splitter = new ThemeSplitView(this);
    auto *sidebar_panel = splitter->Sidebar();
    auto *detail_panel = splitter->Detail();
    pages_ = new wxSimplebook(detail_panel);
    pages_->SetFitToCurrentPage(true);
    auto *buttons = new wxBoxSizer(wxHORIZONTAL);
    progress_ = Theme::ProgressView(this);
    progress_->Hide();
    save_ = new wxButton(this, wxID_SAVE, Localized(StringKey::GlobalActionsSave));
    cancel_ = new wxButton(this, wxID_CANCEL, Localized(StringKey::GlobalActionsCancel));
    auto *sidebar = new wxBoxSizer(wxVERTICAL);
    modules_ = new ProfileModuleList(sidebar_panel, *editor_, [this](std::size_t selection) {
        SelectSection(selection);
    });
    sidebar->Add(modules_, 1, wxEXPAND | wxALL, Theme::Spacing(this));
    sidebar_panel->SetSizer(sidebar);
    auto *detail = new wxBoxSizer(wxVERTICAL);
    detail->Add(pages_, 1, wxEXPAND);
    detail_panel->SetSizer(detail);
    const int sidebar_width = splitter->InitializePanes();
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
    const wxSize viewport(GetCharWidth() * 70, GetCharHeight() * 24);
    auto size = GetSize() - pages_->GetClientSize() + viewport;
    size.IncTo(GetBestSize());
    const auto work_area = wxDisplay(this).GetClientArea();
    size.DecTo(work_area.GetSize());
    SetSize(size);
    splitter->SetSashPosition(sidebar_width);
    timer_.Start(100);
    CentreOnParent();
    auto position = GetPosition();
    position.x = std::max(work_area.x, std::min(position.x, work_area.GetRight() - GetSize().x + 1));
    position.y = std::max(work_area.y, std::min(position.y, work_area.GetBottom() - GetSize().y + 1));
    Move(position);
}

void ProfileCoordinator::ShowSection(wxWindow *page, const wxString &title) {
    wxWindowUpdateLocker update(this);
    pages_->AddPage(page, title, true);
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
    const auto open_content = [this](wxString title, wxString content) {
        ThemeModal modal(this, title, [title, content](wxWindow *parent) {
            return new ThemeLongContent(parent, title, content);
        });
        modal.ShowModal();
    };
    const auto open_list = [this](wxString title, std::vector<std::string> values) {
        ThemeModal modal(this, title, [title, values](wxWindow *parent) {
            return new ThemeTextList(parent, title, values);
        });
        modal.ShowModal();
    };
    wxWindow *page = std::visit([&](const auto &tagged) -> wxWindow * {
        using namespace Partout::Models;
        using Tag = std::decay_t<decltype(tagged)>;
        if constexpr (std::is_same_v<Tag, TaggedModuleDns>) return new DNSView(pages_, tagged.value, open_content);
        else if constexpr (std::is_same_v<Tag, TaggedModuleOnDemand>) return new OnDemandView(pages_, tagged.value);
        else if constexpr (std::is_same_v<Tag, TaggedModuleHTTPProxy>) return new HTTPProxyView(pages_, tagged.value, open_content);
        else if constexpr (std::is_same_v<Tag, TaggedModuleIp>) return new IPView(pages_, tagged.value, open_content);
        else if constexpr (std::is_same_v<Tag, TaggedModuleWireGuard>) return new WireGuardView(pages_, tagged.value, open_content, keys_, open_list);
        else if constexpr (std::is_same_v<Tag, TaggedModuleOpenVpn>) {
            return new OpenVPNView(pages_, tagged.value, open_content, [this, index] {
                const auto module = std::get<TaggedModuleOpenVpn>(editor_->Snapshot().draft.modules.at(index));
                OpenVpnCredentials credentials{};
                credentials.otpMethod.value = OpenVpnCredentialsOTPMethod::none;
                if (module.value.credentials) credentials = *module.value.credentials;
                const auto update = [&credentials](std::string username, std::string password) {
                    credentials.username = std::move(username);
                    credentials.password = std::move(password);
                };
                ThemeModal modal(this, Localized(StringKey::ModulesOpenvpnCredentials),
                    [&credentials, update](wxWindow *parent) {
                        return new OpenVPNCredentialsView(parent, credentials, update);
                    }, ThemeModal::Mode::Editable, ThemeModal::Sizing::Content);
                if (modal.ShowModal() != wxID_OK) return;
                auto updated = std::get<TaggedModuleOpenVpn>(editor_->Snapshot().draft.modules.at(index));
                // Preserve properties outside this editor from the latest profile draft.
                auto accepted = updated.value.credentials.value_or(credentials);
                accepted.username = std::move(credentials.username);
                accepted.password = std::move(credentials.password);
                updated.value.credentials = std::move(accepted);
                editor_->UpdateModule(updated);
                RefreshState();
            }, [this, index, open_list] {
                const auto draft = editor_->Snapshot().draft;
                const auto &module = std::get<TaggedModuleOpenVpn>(draft.modules.at(index)).value;
                if (!module.configuration || !module.configuration->remotes) return;
                open_list(Localized(StringKey::ModulesOpenvpnRemotes), *module.configuration->remotes);
            });
        } else {
            return new ThemeDetailView(pages_);
        }
    }, module);
    ShowSection(page, Modules::Title(module));
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
