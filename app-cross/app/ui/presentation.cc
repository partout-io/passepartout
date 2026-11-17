// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "presentation.h"

namespace Passepartout {
void PresentError(wxWindow *parent, StringKey message) {
    wxMessageDialog dialog(parent, Localized(message), wxTheApp->GetAppName(), wxOK | wxICON_ERROR);
    dialog.SetOKLabel(Localized(StringKey::GlobalNounsOk));
    dialog.ShowModal();
}
void OpenURL(wxWindow *parent, const std::string &url) {
    if (url.compare(0, 8, "https://") != 0 || !wxLaunchDefaultBrowser(wxString::FromUTF8(url))) PresentError(parent);
}
}
