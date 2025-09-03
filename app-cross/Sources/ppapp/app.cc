/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include "passepartout/app.h"

bool MyApp::OnInit()
{
    MyFrame* frame = new MyFrame();
    frame->Show(true);
    return true;
}

MyFrame::MyFrame()
    : wxFrame(nullptr, wxID_ANY, "Menu Bar App")
{
    wxMenuBar* menuBar = new wxMenuBar;

    // Application menu (macOS merges this under the app name)
    wxMenu* appMenu = new wxMenu;
    appMenu->Append(wxID_ABOUT, "&About");
    appMenu->AppendSeparator();
    appMenu->Append(wxID_EXIT, "Quit");

    // Dummy menu
    wxMenu* dummyMenu = new wxMenu;
    dummyMenu->Append(ID_Dummy1, "Dummy Item 1");
    dummyMenu->Append(ID_Dummy2, "Dummy Item 2");

    // macOS expects the first menu to be the App menu
    menuBar->Append(appMenu, "App");
    menuBar->Append(dummyMenu, "Dummy");

    SetMenuBar(menuBar);

    Bind(wxEVT_MENU, &MyFrame::OnAbout, this, wxID_ABOUT);
    Bind(wxEVT_MENU, &MyFrame::OnQuit, this, wxID_EXIT);
    Bind(wxEVT_MENU, &MyFrame::OnDummy1, this, ID_Dummy1);
    Bind(wxEVT_MENU, &MyFrame::OnDummy2, this, ID_Dummy2);

    SetSize(400, 300);
    Centre();
}

void MyFrame::OnDummy1(wxCommandEvent&)
{
    wxLogMessage("Dummy Item 1 clicked");
}

void MyFrame::OnDummy2(wxCommandEvent&)
{
    wxLogMessage("Dummy Item 2 clicked");
}

void MyFrame::OnAbout(wxCommandEvent&)
{
    wxMessageBox("This is a simple wxWidgets macOS menu bar app.", "About", wxOK | wxICON_INFORMATION);
}

void MyFrame::OnQuit(wxCommandEvent&)
{
    Close(true);
}
