/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#pragma once
#include <wx/wx.h>

wxDECLARE_EVENT(wxEVT_ABI_EVENT, wxCommandEvent);
void onABIEvent(void *ctx, const char *event_json);
