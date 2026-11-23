// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "Credits.h"
#include <algorithm>

namespace Passepartout {
Models::Platform::ePlatform CurrentPlatform() {
#ifdef _WIN32
    return Models::Platform::windows;
#else
    return Models::Platform::unixLike;
#endif
}
void FilterCredits(Models::Credits &credits, Models::Platform::ePlatform platform) {
    auto &licenses = credits.licenses;
    licenses.erase(std::remove_if(licenses.begin(), licenses.end(), [platform](const auto &license) {
        return license.platforms && std::none_of(license.platforms->begin(), license.platforms->end(), [platform](const auto &value) {
            return value.value == platform;
        });
    }), licenses.end());
}
}
