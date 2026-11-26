// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "Issue.h"

namespace Passepartout::Windows::Issue {
bool Review(const std::string &recipient_address, const Models::Issue &issue);
}
