/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <wx/wx.h>

class MyApp : public wxApp
{
public:
    bool OnInit() override;
    void OnActivate(wxActivateEvent &event);
};

class MyFrame : public wxFrame
{
public:
    MyFrame();

private:
    void OnImportProfile(wxCommandEvent &event);
    void OnFlushLog(wxCommandEvent &event);
    void OnAbout(wxCommandEvent &event);
    void OnQuit(wxCommandEvent &event);
};

enum {
    ID_ImportProfile = 100,
    ID_FlushLog
};
