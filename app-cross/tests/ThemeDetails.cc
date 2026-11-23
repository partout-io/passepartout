// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "../app/ui/theme/ThemeDetailView.h"
#include "../app/ui/profile/DNSView.h"
#include "../app/ui/profile/OpenVPNView.h"
#include "../app/ui/theme/ThemeLongContent.h"
#include "../app/strings/Strings.h"
#include "../app/ui/settings/SettingsView.h"
#include "../app/ui/settings/IssueReportView.h"
#include "../app/ui/theme/ThemeModal.h"
#include <cstdio>
#include <cstdlib>
#include <wx/simplebook.h>
#include <wx/dataview.h>
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
        using namespace Passepartout;
        auto *typed = new ModuleDetailView(&frame, [](wxString, wxString) {});
        typed->Section("Typed values");
        typed->Row("Missing", std::optional<std::string>{});
        typed->Row("Empty", std::optional<std::vector<std::string>>{{}});
        typed->Row("False", std::optional<bool>{false});
        typed->Row("Zero", std::optional<int>{0});
        typed->Row("Secret", std::optional<std::string>{"typed-secret"}, true, std::nullopt, true);
        typed->IP("Additional routes", std::nullopt,
            std::vector<Partout::Models::Route>{{std::string("10.0.0.0/8"), std::nullopt}}, true);
        typed->Finish();
        if (wxWindow::FindWindowByLabel("Missing", typed) ||
            wxWindow::FindWindowByLabel("Empty", typed) ||
            wxWindow::FindWindowByLabel("typed-secret", typed)) return 19;
        if (!wxWindow::FindWindowByLabel("False", typed) ||
            !wxWindow::FindWindowByLabel("Zero", typed) ||
            !wxWindow::FindWindowByLabel(Localized(StringKey::GlobalNounsDestination), typed)) return 20;
        for (const auto &protocol : std::vector<Partout::Models::DNSModuleProtocolType>{
            Partout::Models::DNSModuleProtocolTypeCleartext{},
            Partout::Models::DNSModuleProtocolTypeHttps{"https", "https://example.com/dns-query"},
            Partout::Models::DNSModuleProtocolTypeTls{"tls", "dns.example.com"}}) {
            Partout::Models::DNSModule module{};
            module.protocolType = protocol;
            module.domainName = "example.com";
            auto *view = new DNSView(&frame, module, [](wxString, wxString) {});
            const bool cleartext = std::holds_alternative<Partout::Models::DNSModuleProtocolTypeCleartext>(protocol);
            if (bool(wxWindow::FindWindowByLabel(Localized(StringKey::EntitiesDnsDomains), view)) != cleartext) return 21;
        }
        for (const auto &method : std::vector<Partout::Models::OpenVpnObfuscationMethod>{
            Partout::Models::OpenVpnObfuscationMethodObfuscate{"obfuscate", "AQI="},
            Partout::Models::OpenVpnObfuscationMethodXormask{"xormask", "AQI="},
            Partout::Models::OpenVpnObfuscationMethodReverse{},
            Partout::Models::OpenVpnObfuscationMethodXorptrpos{}}) {
            Partout::Models::OpenVPNModule module{};
            module.configuration = Partout::Models::OpenVpnConfiguration{};
            module.configuration->xorMethod = method;
            module.configuration->randomizeEndpoint = false;
            module.configuration->keepAliveInterval = 0;
            auto *view = new OpenVPNView(&frame, module, [](wxString, wxString) {}, [] {}, [] {});
            if (!wxWindow::FindWindowByLabel("XOR", view) ||
                !wxWindow::FindWindowByLabel(Localized(StringKey::ModulesOpenvpnRandomizeEndpoint), view) ||
                !wxWindow::FindWindowByLabel(Localized(StringKey::GlobalNounsInterval), view)) return 22;
        }
        Passepartout::IssueReportView *report = nullptr;
        Passepartout::ThemeModal report_modal(&frame, "Report", [&report](wxWindow *parent) {
            report = new Passepartout::IssueReportView(parent);
            return report;
        }, Passepartout::ThemeModal::Mode::Editable, Passepartout::ThemeModal::Sizing::TextInput,
            [&report] { return report->CanSubmit(); });
        auto *ok = report_modal.FindWindow(wxID_OK);
        auto *comment = dynamic_cast<wxTextCtrl *>(wxWindow::FindWindowByName(
            Passepartout::Localized(Passepartout::StringKey::GlobalNounsComment), report));
        if (!ok || !comment || ok->IsEnabled() || report->CanSubmit()) return 12;
        if (comment->GetMinSize() != wxSize(report->GetCharWidth() * 40,
            report->GetCharHeight() * 8)) return 15;
        const auto extra = report_modal.GetSize() - report_modal.GetMinSize();
        if (extra != wxSize(report->GetCharWidth() * 20, report->GetCharHeight() * 4)) return 16;
        comment->SetValue("A report comment");
        ok->UpdateWindowUI();
        if (!ok->IsEnabled() || report->Comment() != "A report comment") return 13;
        comment->Clear();
        ok->UpdateWindowUI();
        if (ok->IsEnabled() || report->CanSubmit()) return 14;
        const wxString secret = "secret-key-value";
        auto *secure_row = new Passepartout::ThemeDetailView(&frame,
            Passepartout::ThemeDetailView::Presentation::Form);
        secure_row->Section("Keys");
        secure_row->LongContent("Private key", secret, [] {}, true);
        auto *app_log = secure_row->ButtonRow("App", [] {});
        auto *tunnel_log = secure_row->ButtonRow("A longer localized tunnel label", [] {}, "Unavailable");
        if (app_log->GetMinSize().x != tunnel_log->GetMinSize().x ||
            tunnel_log->GetMinSize().x < tunnel_log->GetBestSize().x) return 10;
        secure_row->EndSection();
        secure_row->ButtonRow("An unrelated much longer report action", [] {});
        if (app_log->GetMinSize().x != tunnel_log->GetMinSize().x) return 11;
        secure_row->Finish();
        if (wxWindow::FindWindowByLabel(secret, secure_row)) return 7;
        if (!wxWindow::FindWindowByLabel(Passepartout::Localized(
            Passepartout::StringKey::GlobalActionsEdit), secure_row)) return 8;
        auto *content = new Passepartout::ThemeLongContent(&frame, "Private key", secret);
        wxTextCtrl *editor = nullptr;
        for (auto *child : content->GetChildren()) {
            if (auto *text = dynamic_cast<wxTextCtrl *>(child)) editor = text;
        }
        if (!editor || editor->GetValue() != secret || editor->IsEditable() ||
            (editor->GetWindowStyleFlag() & wxTE_PASSWORD)) return 9;
        editor->SetSelection(0, 6);
        content->SetContent(secret + "\nAn additional log line");
        if (editor->GetStringSelection() != "secret") return 17;
        content->SetContent("new");
        if (editor->GetStringSelection() != "new" || editor->IsEditable()) return 18;
        auto *book = new wxSimplebook(&frame);
        int changes = 0;
        auto *sidebar = new Passepartout::SettingsView(&frame, "Update",
            Passepartout::SettingsSection::Preferences, [&](Passepartout::SettingsSection section) {
                if (section == Passepartout::SettingsSection::Update) std::exit(3);
                ++changes;
                book->DeleteAllPages();
                auto *page = new Passepartout::ThemeDetailView(book, Passepartout::ThemeDetailView::Presentation::Plain);
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
                for (int row = 0; row < 3; ++row) {
                    wxKeyEvent event(wxEVT_CHAR_HOOK);
                    event.m_keyCode = direction;
                    event.SetEventObject(list);
                    list->GetEventHandler()->ProcessEvent(event);
                }
            }
        }
        if (changes != 18 || book->GetPageCount() != 1) return 5;
    }
    wxTheApp->OnExit();
    wxEntryCleanup();
    return 0;
}
