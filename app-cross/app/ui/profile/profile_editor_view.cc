// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "profile_editor_view.h"
#include "openvpn_view.h"
#include "openvpn_credentials_view.h"
#include "dns_view.h"
#include "http_proxy_view.h"
#include "ip_view.h"
#include "wireguard_view.h"
#include "../long_content_view.h"
#include "../presentation.h"
#include "../extensions/module.h"
#include "../../strings/unlocalized.h"
#include <type_traits>

namespace Passepartout {
ProfileEditorView::ProfileEditorView(wxWindow *parent, ProfileObservable &profiles,
    std::shared_ptr<ProfileEditor> editor, const WireGuardKeyGenerator &keys)
    : wxDialog(parent, wxID_ANY, Localized(StringKey::GlobalNounsProfile), wxDefaultPosition,
        wxDefaultSize, wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER),
      profiles_(profiles), editor_(std::move(editor)), keys_(keys), timer_(this) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    pages_ = new wxSimplebook(this);
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
    SetMinSize(FromDIP(wxSize(540, 420)));
    SetSize(FromDIP(wxSize(680, 600)));
    back_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        Back();
    });
    cancel_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        if (!editor_->Snapshot().saving) EndModal(wxID_CANCEL);
    });
    save_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        profiles_.SaveEditor(editor_);
        Refresh();
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
        Refresh();
    });
    Overview();
    Refresh();
    timer_.Start(100);
    CentreOnParent();
}
void ProfileEditorView::Push(wxWindow *page, const wxString &title) {
    pages_->AddPage(page, title, true);
    titles_.push_back(title);
    SetTitle(title);
    back_->Show(titles_.size() > 1);
    save_->Show(titles_.size() == 1);
    Layout();
    page->SetFocus();
}
void ProfileEditorView::Back() {
    if (editor_->Snapshot().saving) return;
    if (titles_.size() == 1) {
        EndModal(wxID_CANCEL);
        return;
    }
    pages_->DeletePage(pages_->GetPageCount() - 1);
    titles_.pop_back();
    pages_->SetSelection(pages_->GetPageCount() - 1);
    SetTitle(titles_.back());
    back_->Show(titles_.size() > 1);
    save_->Show(titles_.size() == 1);
    Layout();
    pages_->GetCurrentPage()->SetFocus();
}
void ProfileEditorView::Overview() {
    const auto draft = editor_->Snapshot().draft;
    auto *view = new ThemeDetailView(pages_);
    auto *name = view->TextField(Localized(StringKey::GlobalNounsName), wxString::FromUTF8(draft.name));
    name->Bind(wxEVT_TEXT, [this, name](wxCommandEvent &) {
        editor_->Rename(name->GetValue().ToStdString(wxConvUTF8));
        Refresh();
    });
    view->Section(Localized(StringKey::GlobalNounsModules));
    for (std::size_t index = 0; index < draft.modules.size(); ++index) {
        const auto &module = draft.modules[index];
        if (std::holds_alternative<Partout::Models::TaggedModuleCustom>(module)) continue;
        const bool enabled = std::visit([&](const auto &tagged) {
            if constexpr (std::is_same_v<std::decay_t<decltype(tagged)>, Partout::Models::TaggedModuleCustom>) return false;
            else return std::find(draft.activeModulesIds.begin(), draft.activeModulesIds.end(), tagged.value.id) != draft.activeModulesIds.end();
        }, module);
        const auto title = ModuleTitle(module) + " (" + Localized(enabled ? StringKey::GlobalNounsEnabled : StringKey::GlobalNounsDisabled) + ")";
        auto *action = view->Action(title, [this, index] {
            OpenModule(index);
        });
        action->Enable(!std::holds_alternative<Partout::Models::TaggedModuleOnDemand>(module));
    }
    // Profile identifiers are raw configuration vocabulary, never translated.
    auto id = wxString::FromUTF8(draft.id).Upper();
    id.Replace("-", "");
    wxString grouped;
    for (std::size_t i = 0; i < id.size(); ++i) {
        if (i && i % 4 == 0) grouped += i % 16 == 0 ? '\n' : ' ';
        grouped += id[i];
    }
    if (auto *identifier = view->Field(Strings::Unlocalized::UUID, grouped))
        identifier->SetFont(wxFontInfo(identifier->GetFont().GetPointSize()).Family(wxFONTFAMILY_TELETYPE));
    view->Finish();
    Push(view, Localized(StringKey::GlobalNounsProfile));
}
void ProfileEditorView::OpenModule(std::size_t index) {
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
void ProfileEditorView::Refresh() {
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
