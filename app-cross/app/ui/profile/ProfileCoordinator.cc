// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileCoordinator.h"
#include "ProfileView.h"
#include "OpenVPNView.h"
#include "OpenVPNCredentialsView.h"
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

namespace Passepartout {
ProfileCoordinator::ProfileCoordinator(wxWindow *parent, ProfileObservable &profiles,
    std::shared_ptr<ProfileEditor> editor, const WireGuardKeyGenerator &keys)
    : wxDialog(parent, wxID_ANY, Localized(StringKey::GlobalNounsProfile), wxDefaultPosition,
        wxDefaultSize, wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER),
      profiles_(profiles), editor_(std::move(editor)), keys_(keys), timer_(this) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    pages_ = new wxSimplebook(this);
    pages_->SetFitToCurrentPage(true);
    layout->Add(pages_, 1, wxEXPAND);
    auto *buttons = new wxBoxSizer(wxHORIZONTAL);
    progress_ = ThemeProgressView(this);
    progress_->Hide();
    back_ = new wxButton(this, wxID_BACKWARD, Localized(StringKey::GlobalActionsBack));
    save_ = new wxButton(this, wxID_SAVE, Localized(StringKey::GlobalActionsSave));
    cancel_ = new wxButton(this, wxID_CANCEL, Localized(StringKey::GlobalActionsCancel));
    buttons->Add(back_);
    buttons->Add(progress_, 0, wxLEFT | wxALIGN_CENTER_VERTICAL, Theme::Spacing(this));
    buttons->AddStretchSpacer();
    buttons->Add(save_, 0, wxRIGHT, Theme::Spacing(this));
    buttons->Add(cancel_);
    layout->Add(buttons, 0, wxEXPAND | wxALL, Theme::Spacing(this));
    SetSizer(layout);
    back_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        Back();
    });
    cancel_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        if (!editor_->Snapshot().saving) EndModal(wxID_CANCEL);
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
        if (event.GetKeyCode() == WXK_ESCAPE) Back();
        else event.Skip();
    });
    Bind(wxEVT_TIMER, [this](wxTimerEvent &) {
        RefreshState();
    });
    auto *overview = new ProfileView(pages_, editor_, [this](std::size_t index) {
        OpenModule(index);
    }, [this] {
        RefreshState();
    });
    Push(overview, Localized(StringKey::GlobalNounsProfile));
    RefreshState();
    GetSizer()->SetSizeHints(this);
    timer_.Start(100);
    CentreOnParent();
}
void ProfileCoordinator::Push(wxWindow *page, const wxString &title) {
    if (!pageSizes_.empty()) pageSizes_.back() = GetSize();
    pages_->AddPage(page, title, true);
    titles_.push_back(title);
    pageSizes_.push_back(wxDefaultSize);
    SetTitle(title);
    back_->Show(titles_.size() > 1);
    save_->Show(titles_.size() == 1);
    pages_->InvalidateBestSize();
    InvalidateBestSize();
    if (titles_.size() > 1) {
        // Scrolled pages report small best sizes, not a useful reading viewport.
        const wxSize viewport(page->GetCharWidth() * 90, page->GetCharHeight() * 28);
        auto size = GetSize() - pages_->GetClientSize() + viewport;
        size.IncTo(GetSize());
        size.IncTo(GetBestSize());
        const auto workArea = wxDisplay(this).GetClientArea();
        size.DecTo(workArea.GetSize());
        SetSize(size);
        auto position = GetPosition();
        position.x = std::max(workArea.x, std::min(position.x, workArea.GetRight() - GetSize().x + 1));
        position.y = std::max(workArea.y, std::min(position.y, workArea.GetBottom() - GetSize().y + 1));
        Move(position);
    }
    Layout();
    page->SetFocus();
}
void ProfileCoordinator::Back() {
    if (editor_->Snapshot().saving) return;
    if (titles_.size() == 1) {
        EndModal(wxID_CANCEL);
        return;
    }
    pages_->DeletePage(pages_->GetPageCount() - 1);
    titles_.pop_back();
    pageSizes_.pop_back();
    pages_->SetSelection(pages_->GetPageCount() - 1);
    SetTitle(titles_.back());
    back_->Show(titles_.size() > 1);
    save_->Show(titles_.size() == 1);
    pages_->InvalidateBestSize();
    InvalidateBestSize();
    SetSize(pageSizes_.back());
    Layout();
    pages_->GetCurrentPage()->SetFocus();
}
void ProfileCoordinator::OpenModule(std::size_t index) {
    const auto module = editor_->Snapshot().draft.modules.at(index);
    const auto openContent = [this](wxString title, wxString content) {
        Push(new LongContentView(pages_, title, content), title);
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
                Push(new OpenVPNCredentialsView(pages_, editor_, index), Localized(StringKey::ModulesOpenvpnCredentials));
            });
        } else return new ThemeDetailView(pages_);
    }, module);
    Push(page, ModuleTitle(module));
}
void ProfileCoordinator::RefreshState() {
    const auto state = editor_->Snapshot();
    if (state.saved) {
        timer_.Stop();
        EndModal(wxID_SAVE);
        return;
    }
    pages_->Enable(!state.saving);
    if (state.saving) progress_->Start();
    else progress_->Stop();
    if (progress_->Show(state.saving)) Layout();
    back_->Enable(!state.saving);
    cancel_->Enable(!state.saving);
    save_->Enable(editor_->CanSave() && ProfileObservable::CanSave(profiles_.Snapshot(), state.draft.id));
    if (state.failed) {
        editor_->ClearError();
        PresentError(this);
    }
}
}
