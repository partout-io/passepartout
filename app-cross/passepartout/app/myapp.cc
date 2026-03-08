/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include "myapp.h"
extern "C" {
#include <stdlib.h>
#include "passepartout.h"
}

bool MyApp::OnInit()
{
#ifdef _WIN32
    // Per-monitor DPI awareness (v2)
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
#endif

    psp_app_init_args args = { 0 };
    char *bundle = NULL;
    char *constants = NULL;
    MyFrame* frame = 0;

    /* Paths to JSON input. */
    const char *bundle_path = "bundle.json";
    const char *constants_path = "constants.json";
    // FIXME: #1656, C ABI, hardcoded profiles dir and cache dir
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
    args.bundle = bundle;
    args.constants = constants;
    args.preferences = NULL;
    args.profiles_dir = profiles_dir;
    args.cache_dir = cache_dir;
    args.event_ctx = NULL;
    args.event_cb = NULL;
    psp_app_init(&args);
    free(bundle);
    free(constants);

    Bind(wxEVT_ACTIVATE_APP, &MyApp::OnActivate, this);

    frame = new MyFrame();
    frame->Show(true);
    return true;
failure:
    if (bundle) free(bundle);
    if (constants) free(constants);
    return false;
}

void MyApp::OnActivate(wxActivateEvent &event) {
    psp_app_on_foreground();
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

    SetSize(400, 300);
    Centre();
}

void MyFrame::OnImportProfile(wxCommandEvent&)
{
    wxFileDialog openFileDialog(this, _("Import profile"), "", "",
                                "Configuration files *.ovpn|*.conf",
                                wxFD_OPEN | wxFD_FILE_MUST_EXIST);

    if (openFileDialog.ShowModal() == wxID_CANCEL) return;

    const wxString path = openFileDialog.GetPath();
    const char *cPath = path.utf8_str().data();
    printf("Path: %s\n", cPath);
    psp_app_import_profile(cPath);
}

void MyFrame::OnFlushLog(wxCommandEvent&)
{
    psp_app_flush_log();
}

void MyFrame::OnAbout(wxCommandEvent&)
{
    wxMessageBox("This is a simple wxWidgets macOS menu bar app.", "About", wxOK | wxICON_INFORMATION);
}

void MyFrame::OnQuit(wxCommandEvent&)
{
    Close(true);
}
