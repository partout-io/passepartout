// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "settings_view.h"
#include "preferences_view.h"
#include "version_view.h"
#include "credits_view.h"
#include "links_view.h"
#include "diagnostics_view.h"
#include "../presentation.h"
#include "../../strings/unlocalized.h"

namespace Passepartout {
SettingsView::SettingsView(wxWindow *parent, AppContext &context, bool showVersion)
    : wxDialog(parent, wxID_ANY, Localized(StringKey::ViewsSettingsTitle), wxDefaultPosition,
        wxDefaultSize, wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER) {
    auto *layout = new wxBoxSizer(wxVERTICAL);
    pages_ = new wxSimplebook(this);
    layout->Add(pages_, 1, wxEXPAND);
    auto *buttons = new wxBoxSizer(wxHORIZONTAL);
    back_ = new wxButton(this, wxID_BACKWARD, Localized(StringKey::GlobalActionsBack));
    auto *close = new wxButton(this, wxID_CANCEL, Localized(StringKey::GlobalActionsClose));
    buttons->Add(back_);
    buttons->AddStretchSpacer();
    buttons->Add(close);
    layout->Add(buttons, 0, wxEXPAND | wxALL, Theme::Spacing(this));
    SetSizer(layout);
    SetMinSize(FromDIP(wxSize(540, 420)));
    SetSize(FromDIP(wxSize(680, 600)));
    const SettingsNavigation navigate = [this](auto title, auto makePage) {
        Push(std::move(title), std::move(makePage));
    };
    const auto versionPage = [&context, navigate](wxWindow *parent) {
        return new VersionView(parent, context.version, wxString::FromUTF8(context.crossConstants.tags.app), navigate);
    };
    Push(Localized(StringKey::ViewsSettingsTitle), [&](wxWindow *parent) {
        auto *main = new ThemeDetailView(parent);
        main->Navigate(Localized(StringKey::GlobalNounsPreferences), [navigate, &context] {
            navigate(Localized(StringKey::GlobalNounsPreferences), [&context](wxWindow *parent) {
                return new PreferencesView(parent, context.preferences);
            });
        });
        main->Navigate(Localized(StringKey::GlobalNounsVersion), [navigate, versionPage] {
            navigate(Localized(StringKey::GlobalNounsVersion), versionPage);
        });
        const auto release = context.version.Snapshot().release;
        if (release.latest) {
            auto title = Localized(StringKey::ViewsSettingsLinksUpdate);
            title.Replace("%@", wxString::FromUTF8(*release.latest));
            main->Navigate(title, [main, url = release.downloadURL] {
                OpenURL(main, url);
            });
        }
        main->Section(Localized(StringKey::GlobalNounsAbout));
        main->Navigate(Localized(StringKey::ViewsSettingsLinksTitle), [navigate, &context] {
            navigate(Localized(StringKey::ViewsSettingsLinksTitle), [&context](wxWindow *parent) {
                return new LinksView(parent, context.constants);
            });
        });
        main->Navigate(Localized(StringKey::ViewsSettingsCreditsTitle), [navigate, &context] {
            navigate(Localized(StringKey::ViewsSettingsCreditsTitle), [&context, navigate](wxWindow *parent) {
                return new CreditsView(parent, context.credits, navigate);
            });
        });
        main->Section(Localized(StringKey::GlobalNounsTroubleshooting));
        main->Navigate(Strings::Unlocalized::FAQ, [main, url = context.constants.websites.homeURL + "/faq"] {
            OpenURL(main, url);
        });
        main->Navigate(Localized(StringKey::ViewsDiagnosticsTitle), [navigate, &context] {
            navigate(Localized(StringKey::ViewsDiagnosticsTitle), [&context, navigate](wxWindow *parent) {
                return new DiagnosticsView(parent, context.diagnostics, context.preferences, navigate);
            });
        });
        main->Finish();
        return main;
    });
    if (showVersion) Push(Localized(StringKey::GlobalNounsVersion), versionPage);
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
    CentreOnParent();
}
void SettingsView::Push(wxString title, std::function<wxWindow *(wxWindow *)> makePage) {
    auto *page = makePage(pages_);
    pages_->AddPage(page, title, true);
    titles_.push_back(std::move(title));
    SetTitle(titles_.back());
    back_->Show(titles_.size() > 1);
    Layout();
    page->SetFocus();
}
void SettingsView::Back() {
    if (titles_.size() == 1) {
        EndModal(wxID_CANCEL);
        return;
    }
    pages_->DeletePage(pages_->GetPageCount() - 1);
    titles_.pop_back();
    pages_->SetSelection(pages_->GetPageCount() - 1);
    SetTitle(titles_.back());
    back_->Show(titles_.size() > 1);
    Layout();
    pages_->GetCurrentPage()->SetFocus();
}
}
