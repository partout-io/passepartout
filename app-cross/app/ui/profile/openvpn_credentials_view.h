// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../theme/detail_view.h"
#include "../../observables/profile_editor.h"

namespace Passepartout {
class OpenVPNCredentialsView final : public ThemeDetailView {
public:
    OpenVPNCredentialsView(wxWindow *parent, std::shared_ptr<ProfileEditor> editor, std::size_t moduleIndex);
};
}
