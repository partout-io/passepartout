/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include "abi.h"
#include "app.h"

wxDEFINE_EVENT(wxEVT_ABI_EVENT, wxCommandEvent);

void onABIEvent(void *ctx, const char *event_json) {
    MyApp *app = (MyApp *)ctx;
//    const wxString app_name = app->GetAppName();
//    const char *c_app_name = app_name.utf8_str().data();
//    printf(">>> ABI Event (%s): %s\n", c_app_name, event_json);

    // Must be heap-allocated
    wxCommandEvent *event = new wxCommandEvent(wxEVT_ABI_EVENT);
    event->SetString(event_json);
    event->SetClientData((void *)ctx);
    wxQueueEvent(app->GetTopWindow(), event);
}
