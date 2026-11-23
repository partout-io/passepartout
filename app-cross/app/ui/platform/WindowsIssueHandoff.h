// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../business/managers/IssueReporter.h"

namespace Passepartout::Windows::Issue {
bool Review(const IssueReport &report);
}
