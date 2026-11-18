// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../theme/ThemeDetailView.h"
#include "../../observables/ProfileEditor.h"

namespace Passepartout {
class OpenVPNCredentialsView final : public ThemeDetailView {
public:
    OpenVPNCredentialsView(wxWindow *parent, std::shared_ptr<ProfileEditor> editor, std::size_t moduleIndex);
};
}
