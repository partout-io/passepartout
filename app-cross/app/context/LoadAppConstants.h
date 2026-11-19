// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppConstants.h"
#include "AppConstantsResource.h"

namespace Passepartout {
inline Models::AppConstants LoadAppConstants() {
    return Models::AppConstants::FromJson(nlohmann::json::parse(appConstantsResource));
}
}
