// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "SettingsCoordinator.h"
#include "PreferencesView.h"
#include "VersionView.h"
#include "CreditsView.h"
#include "LinksView.h"
#include "DiagnosticsView.h"
#include "../Presentation.h"
#include "../../theme/ThemeSplitView.h"
#include <wx/display.h>
#include <wx/wupdlock.h>
#include <algorithm>

namespace Passepartout {
SettingsCoordinator::SettingsCoordinator(wxWindow *parent, AppContext &context, bool showVersion)
    : wxDialog(parent, wxID_ANY, Localized(StringKey::ViewsSettingsTitle), wxDefaultPosition,
        wxDefaultSize, wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER), context_(context) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    auto *splitter = new ThemeSplitView(this);
    auto *detailPanel = splitter->Detail();
    pages_ = new wxSimplebook(detailPanel);
    pages_->SetFitToCurrentPage(true);
    auto *detail = new wxBoxSizer(wxVERTICAL);
    auto *navigation = new wxBoxSizer(wxHORIZONTAL);
    heading_ = new wxStaticText(detailPanel, wxID_ANY, wxString());
    heading_->SetFont(heading_->GetFont().Bold());
    navigation->Add(heading_, 1, wxALIGN_CENTER_VERTICAL);
    back_ = new wxButton(detailPanel, wxID_BACKWARD, Localized(StringKey::GlobalActionsBack));
    navigation->Add(back_, 0, wxALIGN_CENTER_VERTICAL | wxLEFT | wxRESERVE_SPACE_EVEN_IF_HIDDEN,
        Theme::Spacing(this));
    detail->Add(navigation, 0, wxEXPAND | wxALL, Theme::Spacing(this));
    detail->Add(pages_, 1, wxEXPAND);
    detailPanel->SetSizer(detail);
    const auto version = context.version.Snapshot();
    wxString updateTitle;
    if (version.release.latest) {
        updateTitle = Localized(StringKey::ViewsSettingsLinksUpdate);
        updateTitle.Replace("%@", wxString::FromUTF8(*version.release.latest));
    }
    const auto initial = showVersion ? SettingsSection::Version : SettingsSection::Preferences;
    auto *sidebar = new wxBoxSizer(wxVERTICAL);
    sidebar->Add(new SettingsView(splitter->Sidebar(), wxString::FromUTF8(version.current),
        updateTitle, initial, [this](SettingsSection section) {
            SelectSection(section);
        }), 1, wxEXPAND | wxALL, Theme::Spacing(this));
    splitter->Sidebar()->SetSizer(sidebar);
    const int sidebarWidth = splitter->InitializePanes();
    layout->Add(splitter, 1, wxEXPAND);
    auto *buttons = new wxStdDialogButtonSizer;
    auto *close = new wxButton(this, wxID_CANCEL, Localized(StringKey::GlobalActionsClose));
    buttons->SetCancelButton(close);
    buttons->Realize();
    layout->Add(buttons, 0, wxALIGN_RIGHT | wxALL, Theme::Spacing(this));
    SetSizer(layout);
    back_->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        Back();
    });
    close->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        EndModal(wxID_CANCEL);
    });
    Bind(wxEVT_CHAR_HOOK, [this](wxKeyEvent &event) {
        if (event.GetKeyCode() == WXK_ESCAPE) Back();
        else event.Skip();
    });
    SelectSection(initial);
    GetSizer()->SetSizeHints(this);
    const wxSize viewport(GetCharWidth() * 90, GetCharHeight() * 28);
    auto size = GetSize() - pages_->GetClientSize() + viewport;
    size.IncTo(GetBestSize());
    const auto workArea = wxDisplay(this).GetClientArea();
    size.DecTo(workArea.GetSize());
    SetSize(size);
    splitter->SetSashPosition(sidebarWidth);
    CentreOnParent();
    auto position = GetPosition();
    position.x = std::max(workArea.x, std::min(position.x, workArea.GetRight() - GetSize().x + 1));
    position.y = std::max(workArea.y, std::min(position.y, workArea.GetBottom() - GetSize().y + 1));
    Move(position);
}
void SettingsCoordinator::SelectSection(SettingsSection section) {
    if (section == SettingsSection::FAQ) {
        OpenURL(this, context_.constants.websites.homeURL + "/faq");
        return;
    }
    if (section == SettingsSection::Update) {
        OpenURL(this, context_.version.Snapshot().release.downloadURL);
        return;
    }
    if (section == section_ && !titles_.empty()) return;
    wxWindowUpdateLocker update(this);
    section_ = section;
    pages_->DeleteAllPages();
    titles_.clear();
    const SettingsNavigation navigate = [this](auto title, auto makePage) {
        Push(std::move(title), std::move(makePage));
    };
    switch (section) {
        case SettingsSection::Preferences:
            Push(Localized(StringKey::GlobalNounsPreferences), [this](wxWindow *parent) {
                return new PreferencesView(parent, context_.preferences);
            });
            break;
        case SettingsSection::Version:
            Push(Localized(StringKey::GlobalNounsVersion), [this, navigate](wxWindow *parent) {
                return new VersionView(parent, context_.version,
                    wxString::FromUTF8(context_.crossConstants.tags.app), navigate);
            });
            break;
        case SettingsSection::Links:
            Push(Localized(StringKey::ViewsSettingsLinksTitle), [this](wxWindow *parent) {
                return new LinksView(parent, context_.constants);
            });
            break;
        case SettingsSection::Credits:
            Push(Localized(StringKey::ViewsSettingsCreditsTitle), [this, navigate](wxWindow *parent) {
                return new CreditsView(parent, context_.credits, navigate);
            });
            break;
        case SettingsSection::Diagnostics:
            Push(Localized(StringKey::ViewsDiagnosticsTitle), [this, navigate](wxWindow *parent) {
                return new DiagnosticsView(parent, context_.diagnostics, context_.preferences, navigate);
            });
            break;
        default:
            break;
    }
}
void SettingsCoordinator::Push(wxString title, std::function<wxWindow *(wxWindow *)> makePage) {
    wxWindowUpdateLocker update(this);
    auto *page = makePage(pages_);
    pages_->AddPage(page, title, true);
    titles_.push_back(std::move(title));
    RefreshNavigation();
}
void SettingsCoordinator::Back() {
    if (titles_.size() == 1) {
        EndModal(wxID_CANCEL);
        return;
    }
    wxWindowUpdateLocker update(this);
    pages_->DeletePage(pages_->GetPageCount() - 1);
    titles_.pop_back();
    pages_->SetSelection(pages_->GetPageCount() - 1);
    RefreshNavigation();
    pages_->GetCurrentPage()->SetFocus();
}
void SettingsCoordinator::RefreshNavigation() {
    heading_->SetLabel(titles_.back());
    back_->Show(titles_.size() > 1);
    pages_->InvalidateBestSize();
    pages_->GetParent()->Layout();
    InvalidateBestSize();
    Layout();
}
}
