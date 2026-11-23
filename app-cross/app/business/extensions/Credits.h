// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../../models/Credits.h"

namespace Passepartout::Credits {
Models::Platform::ePlatform CurrentPlatform();
void Filter(Models::Credits &credits, Models::Platform::ePlatform platform);
}
