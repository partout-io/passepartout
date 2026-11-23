// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppConstants.h"
#include "AppConstantsResource.h"

namespace Passepartout::Constants {
inline Models::AppConstants Load() {
    return Models::AppConstants::FromJson(Partout::Json::Parse(appConstantsResource));
}
}
