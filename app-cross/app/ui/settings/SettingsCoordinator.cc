// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "SettingsCoordinator.h"
#include "PreferencesView.h"
#include "SettingsPresentation.h"
#include "CreditsView.h"
#include "LinksView.h"
#include "../diagnostics/DiagnosticsView.h"
#include "../diagnostics/IssueReportView.h"
#include "../platform/Presentation.h"
#include "../theme/ThemeSplitView.h"
#include "../theme/ThemeModal.h"
#include <wx/display.h>
#include <wx/wupdlock.h>
#include <algorithm>

namespace Passepartout {
SettingsCoordinator::SettingsCoordinator(wxWindow *parent, AppContext &context)
    : wxDialog(parent, wxID_ANY, Localized(StringKey::ViewsSettingsTitle), wxDefaultPosition,
        wxDefaultSize, wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER), context_(context) {
    Theme::Apply(this);
    SetIcon(Theme::SettingsIcon(this));
    Bind(wxEVT_SYS_COLOUR_CHANGED, [this](wxSysColourChangedEvent &event) {
        SetIcon(Theme::SettingsIcon(this));
        event.Skip();
    });
    Bind(wxEVT_DPI_CHANGED, [this](wxDPIChangedEvent &event) {
        SetIcon(Theme::SettingsIcon(this));
        event.Skip();
    });
    auto *layout = new wxBoxSizer(wxVERTICAL);
    auto *splitter = new ThemeSplitView(this);
    auto *detail_panel = splitter->Detail();
    pages_ = new wxSimplebook(detail_panel);
    pages_->SetFitToCurrentPage(true);
    auto *detail = new wxBoxSizer(wxVERTICAL);
    detail->Add(pages_, 1, wxEXPAND);
    detail_panel->SetSizer(detail);
    const auto version = context.version.Snapshot();
    wxString update_title;
    if (version.release.latest) {
        update_title = Localized(StringKey::ViewsSettingsLinksUpdate);
        update_title.Replace("%@", wxString::FromUTF8(*version.release.latest));
    }
    const auto initial = SettingsSection::Preferences;
    auto *sidebar = new wxBoxSizer(wxVERTICAL);
    sidebar->Add(new SettingsView(splitter->Sidebar(),
        update_title, initial, [this](SettingsSection section) {
            SelectSection(section);
        }), 1, wxEXPAND | wxALL, Theme::Spacing(this));
    splitter->Sidebar()->SetSizer(sidebar);
    const int sidebar_width = splitter->InitializePanes();
    layout->Add(splitter, 1, wxEXPAND);
    auto *buttons = new wxStdDialogButtonSizer;
    auto *close = new wxButton(this, wxID_CANCEL, Localized(StringKey::GlobalActionsClose));
    buttons->SetCancelButton(close);
    buttons->Realize();
    layout->Add(buttons, 0, wxALIGN_RIGHT | wxALL, Theme::Spacing(this));
    SetSizer(layout);
    SetEscapeId(wxID_CANCEL);
    SelectSection(initial);
    GetSizer()->SetSizeHints(this);
    const wxSize viewport(GetCharWidth() * 90, GetCharHeight() * 28);
    auto size = GetSize() - pages_->GetClientSize() + viewport;
    size.IncTo(GetBestSize());
    const auto work_area = wxDisplay(this).GetClientArea();
    size.DecTo(work_area.GetSize());
    SetSize(size);
    splitter->SetSashPosition(sidebar_width);
    CentreOnParent();
    auto position = GetPosition();
    position.x = std::max(work_area.x, std::min(position.x, work_area.GetRight() - GetSize().x + 1));
    position.y = std::max(work_area.y, std::min(position.y, work_area.GetBottom() - GetSize().y + 1));
    Move(position);
}

void SettingsCoordinator::SelectSection(SettingsSection section) {
    if (section == SettingsSection::Update) {
        OpenURL(this, context_.version.Snapshot().release.download_url);
        return;
    }
    if (section == section_ && pages_->GetPageCount() != 0) return;
    wxWindowUpdateLocker update(this);
    section_ = section;
    pages_->DeleteAllPages();
    const SettingsPresentation present = [this](auto title, auto make_page) {
        ThemeModal modal(this, title, make_page);
        modal.ShowModal();
    };
    switch (section) {
        case SettingsSection::Preferences:
            ShowSection(new PreferencesView(pages_, context_.preferences),
                Localized(StringKey::GlobalNounsPreferences)
            );
            break;
        case SettingsSection::Links:
            ShowSection(new LinksView(pages_, context_.constants),
                Localized(StringKey::ViewsSettingsLinksTitle)
            );
            break;
        case SettingsSection::Credits:
            ShowSection(new CreditsView(pages_, context_.credits, present),
                Localized(StringKey::ViewsSettingsCreditsTitle)
            );
            break;
        case SettingsSection::Diagnostics:
            ShowSection(new DiagnosticsView(pages_, context_.diagnostics, context_.preferences, context_.profiles, context_.tunnel, present, [this] { ReportIssue(); }),
                Localized(StringKey::ViewsDiagnosticsTitle)
            );
            break;
        default:
            break;
    }
}

void SettingsCoordinator::ReportIssue() {
    IssueReportView *view = nullptr;
    ThemeModal modal(this, Localized(StringKey::ViewsDiagnosticsReportIssueTitle),
        [&view](wxWindow *parent) {
            view = new IssueReportView(parent);
            return view;
        }, ThemeModal::Mode::Editable, ThemeModal::Sizing::TextInput,
        [&view] { return view && view->CanSubmit(); }
    );
    if (modal.ShowModal() != wxID_OK) return;
    try {
        if (!context_.diagnostics.Report(
            view->Comment(), context_.cross_constants.app, context_.constants.log.filenames.app
        )) {
            PresentError(this, StringKey::ViewsDiagnosticsAlertsReportIssueEmail);
        }
    } catch (...) {
        PresentError(this);
    }
}

void SettingsCoordinator::ShowSection(wxWindow *page, const wxString &title) {
    pages_->AddPage(page, title, true);
    pages_->InvalidateBestSize();
    pages_->GetParent()->Layout();
    InvalidateBestSize();
    Layout();
}
}
