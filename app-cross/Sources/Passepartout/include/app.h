/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <wx/wx.h>

// From app-shared ABI
extern "C" int example(int a, int b);

class MyApp : public wxApp
{
public:
    virtual bool OnInit() override;
};

class MyFrame : public wxFrame
{
public:
    MyFrame();

private:
    void OnDummy1(wxCommandEvent& event);
    void OnDummy2(wxCommandEvent& event);
    void OnAbout(wxCommandEvent& event);
    void OnQuit(wxCommandEvent& event);
};

enum
{
    ID_Dummy1 = 1,
    ID_Dummy2
};
