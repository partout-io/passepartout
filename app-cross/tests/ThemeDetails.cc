// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "../app/theme/ThemeDetailView.h"
#include "../app/ui/settings/SettingsView.h"
#include <cstdio>
#include <cstdlib>
#include <wx/simplebook.h>
#include <wx/uilocale.h>

class ThemeDetails final : public wxApp {
public:
    bool OnInit() override {
        return true;
    }
};
wxIMPLEMENT_APP_NO_MAIN(ThemeDetails);

int main(int argc, char **argv) {
    if (!wxEntryStart(argc, argv)) return 1;
    wxSetAssertHandler([](const wxString &file, int line, const wxString &function,
        const wxString &condition, const wxString &message) {
        std::fprintf(stderr, "%s:%d %s: %s (%s)\n", file.utf8_str().data(), line,
            function.utf8_str().data(), message.utf8_str().data(), condition.utf8_str().data());
        std::exit(2);
    });
    if (!wxTheApp->CallOnInit()) return 1;
    for (const auto *tag : {"fr-FR", "pt-BR", "en-US", "zh-Hans"}) {
        const auto *info = wxUILocale::FindLanguageInfo(wxLocaleIdent::FromTag(tag));
        if (!info || info->Description.empty() || info->Description == tag) return 6;
    }
    {
        wxFrame frame(nullptr, wxID_ANY, "Presentation regression");
        auto *book = new wxSimplebook(&frame);
        int changes = 0;
        auto *sidebar = new Passepartout::SettingsView(&frame, "Test", "Update",
            Passepartout::SettingsSection::Preferences, [&](Passepartout::SettingsSection section) {
                if (section == Passepartout::SettingsSection::FAQ ||
                    section == Passepartout::SettingsSection::Update) std::exit(3);
                ++changes;
                book->DeleteAllPages();
                auto *page = new Passepartout::ThemeDetailView(book);
                page->Section("Support");
                page->ExternalLink("Discussion", [] {});
                page->Section("Web");
                for (int row = 0; row < 4; ++row) page->ExternalLink("Website", [] {});
                // Credits uses this static row; conflicting box-sizer flags used
                // to trigger the same DoInsert breakpoint recorded by Windows.
                page->Field("Language", "Contributor");
                page->Finish();
                book->AddPage(page, "Details", true);
                book->SetSize(600, 400);
                book->Layout();
            });
        wxDataViewListCtrl *list = nullptr;
        for (auto *child : sidebar->GetChildren()) {
            if (auto *candidate = dynamic_cast<wxDataViewListCtrl *>(child)) list = candidate;
        }
        if (!list) return 4;
        for (int cycle = 0; cycle < 3; ++cycle) {
            for (const int direction : {WXK_DOWN, WXK_UP}) {
                for (int row = 0; row < 4; ++row) {
                    wxKeyEvent event(wxEVT_CHAR_HOOK);
                    event.m_keyCode = direction;
                    event.SetEventObject(list);
                    list->GetEventHandler()->ProcessEvent(event);
                }
            }
        }
        if (changes != 24 || book->GetPageCount() != 1) return 5;
    }
    wxTheApp->OnExit();
    wxEntryCleanup();
    return 0;
}
