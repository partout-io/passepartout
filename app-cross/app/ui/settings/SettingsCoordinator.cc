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
#include "../../theme/ThemeModal.h"
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
    heading_ = new wxStaticText(detailPanel, wxID_ANY, {});
    heading_->SetFont(heading_->GetFont().Bold());
    detail->Add(heading_, 0, wxEXPAND | wxALL, Theme::Spacing(this));
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
    close->Bind(wxEVT_BUTTON, [this](wxCommandEvent &) {
        EndModal(wxID_CANCEL);
    });
    Bind(wxEVT_CHAR_HOOK, [this](wxKeyEvent &event) {
        if (event.GetKeyCode() == WXK_ESCAPE) EndModal(wxID_CANCEL);
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
    if (section == section_ && pages_->GetPageCount() != 0) return;
    wxWindowUpdateLocker update(this);
    section_ = section;
    pages_->DeleteAllPages();
    const SettingsPresentation present = [this](auto title, auto makePage) {
        ThemeModal modal(this, title, makePage);
        modal.ShowModal();
    };
    switch (section) {
        case SettingsSection::Preferences:
            ShowSection(Localized(StringKey::GlobalNounsPreferences), [this](wxWindow *parent) {
                return new PreferencesView(parent, context_.preferences);
            });
            break;
        case SettingsSection::Version:
            ShowSection(Localized(StringKey::GlobalNounsVersion), [this, present](wxWindow *parent) {
                return new VersionView(parent, context_.version,
                    wxString::FromUTF8(context_.crossConstants.tags.app), present);
            });
            break;
        case SettingsSection::Links:
            ShowSection(Localized(StringKey::ViewsSettingsLinksTitle), [this](wxWindow *parent) {
                return new LinksView(parent, context_.constants);
            });
            break;
        case SettingsSection::Credits:
            ShowSection(Localized(StringKey::ViewsSettingsCreditsTitle), [this, present](wxWindow *parent) {
                return new CreditsView(parent, context_.credits, present);
            });
            break;
        case SettingsSection::Diagnostics:
            ShowSection(Localized(StringKey::ViewsDiagnosticsTitle), [this, present](wxWindow *parent) {
                return new DiagnosticsView(parent, context_.diagnostics, context_.preferences, present);
            });
            break;
        default:
            break;
    }
}
void SettingsCoordinator::ShowSection(wxString title, std::function<wxWindow *(wxWindow *)> makePage) {
    wxWindowUpdateLocker update(this);
    auto *page = makePage(pages_);
    pages_->AddPage(page, title, true);
    heading_->SetLabel(title);
    pages_->InvalidateBestSize();
    pages_->GetParent()->Layout();
    InvalidateBestSize();
    Layout();
}
}
