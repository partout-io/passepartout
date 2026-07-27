/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include "app.h"
#include "abi.h"

#include <stdlib.h>
// Imported as a Clang C module (CommonLibrary_C); already has C linkage, so it
// must not be wrapped in an extern "C" block.
#include "passepartout.h"

bool MyApp::OnInit()
{
#ifdef _WIN32
    // Per-monitor DPI awareness (v2)
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
#endif
    MyFrame* frame = 0;
    char *bundle = NULL;
    char *constants = NULL;

    const char *bundle_path = "bundle.json";
    const char *constants_path = "constants.json";
    // FIXME: #209/notes, Cross UI, hardcoded profiles dir and cache dir
    const char *profiles_dir = ".";
    const char *cache_dir = ".";
#ifdef USE_SWIFTPM
    const char *parent = "app-cross_passepartout-shared.bundle/Contents/Resources/assets";
#else
    const char *parent = NULL;
#endif
    if ((bundle = psp_readfile(bundle_path, parent)) == NULL) {
        fprintf(stderr, "Unable to open bundle: %s\n", bundle_path);
        goto failure;
    }
    if ((constants = psp_readfile(constants_path, parent)) == NULL) {
        fprintf(stderr, "Unable to open constants: %s\n", constants_path);
        goto failure;
    }

    {
        psp_app_init_args args = {};
        args.bundle = bundle;
        args.constants = constants;
        args.preferences = NULL;
        args.profiles_dir = profiles_dir;
        args.cache_dir = cache_dir;
        // NULL selects the default declarative config location
        // (~/.config/passepartout.json); the library loads it on foreground.
        args.config_path = NULL;
        args.bindings.event_ctx = this;
        args.bindings.event_cb = onABIEvent;
        args.bindings.request_ctx = NULL;
        args.bindings.request_cb = NULL;
        args.bindings.free = NULL;
        if (psp_app_init(&args) != PSPCompletionCodeOK) {
            fprintf(stderr, "Unable to initialize app ABI\n");
            goto failure;
        }
    }
    free(bundle);
    free(constants);
    bundle = NULL;
    constants = NULL;

    Bind(wxEVT_ACTIVATE_APP, &MyApp::OnActivateApp, this);

    frame = new MyFrame();
    frame->Show(true);

    // Drive the initial foreground so the library runs its launch task and
    // applies the declarative config, mirroring the Apple app at startup.
    psp_app_on_foreground();

    return true;
failure:
    if (bundle) free(bundle);
    if (constants) free(constants);
    return false;
}

void MyApp::OnActivateApp(wxActivateEvent &event) {
    if (event.GetActive()) {
        psp_app_on_foreground();
    }
    event.Skip();
}

MyFrame::MyFrame()
    : wxFrame(nullptr, wxID_ANY, "Passepartout")
{
    wxMenuBar* menuBar = new wxMenuBar;

    // Application menu (macOS merges this under the app name)
    wxMenu* appMenu = new wxMenu;
    appMenu->Append(wxID_ABOUT, "&About");
    appMenu->Append(wxID_EXIT, "Quit");

    wxMenu* actionsMenu = new wxMenu;
    actionsMenu->Append(ID_ImportProfile, "Import profile");
    actionsMenu->Append(ID_FlushLog, "Flush log");
    const wxString partoutVersion = wxString::Format("Partout %s", psp_partout_version());
    actionsMenu->Append(wxID_ANY, partoutVersion);

    // macOS expects the first menu to be the App menu
    menuBar->Append(appMenu, "App");
    menuBar->Append(actionsMenu, "Actions");

    SetMenuBar(menuBar);

    Bind(wxEVT_MENU, &MyFrame::OnImportProfile, this, ID_ImportProfile);
    Bind(wxEVT_MENU, &MyFrame::OnFlushLog, this, ID_FlushLog);
    Bind(wxEVT_MENU, &MyFrame::OnAbout, this, wxID_ABOUT);
    Bind(wxEVT_MENU, &MyFrame::OnQuit, this, wxID_EXIT);
    Bind(wxEVT_ABI_EVENT, &MyFrame::OnABIEvent, this);

    SetSize(400, 300);
    Centre();
}

void MyFrame::OnImportProfile(wxCommandEvent &)
{
    wxFileDialog openFileDialog(this, _("Import profile"), "", "",
                                "*.ovpn;*.conf;*.json",
                                wxFD_OPEN | wxFD_FILE_MUST_EXIST);

    if (openFileDialog.ShowModal() == wxID_CANCEL) return;

    const wxString path = openFileDialog.GetPath();
    const wxScopedCharBuffer utf8Path = path.utf8_str();
    psp_app_import_profile_path(utf8Path.data(), PSP_CB(this, [](void *ctx, int code, const char *json) {
        printf(">>> Import result: (ctx=%p), code=%d, %s\n", ctx, code, json ? json : "(null)");
    }));
}

void MyFrame::OnFlushLog(wxCommandEvent &)
{
    psp_app_flush_log();
}

void MyFrame::OnAbout(wxCommandEvent &)
{
    wxMessageBox("This is a simple wxWidgets macOS menu bar app.", "About", wxOK | wxICON_INFORMATION);
}

void MyFrame::OnQuit(wxCommandEvent &)
{
    Close(true);
}

void MyFrame::OnABIEvent(wxCommandEvent &event)
{
    const wxString json = event.GetString();
    const wxScopedCharBuffer utf8JSON = json.utf8_str();
    printf(">>> ABI Event (MyFrame): %s\n", utf8JSON.data());
}
