// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../models/Profile.h"

namespace Passepartout {
class ProfileRepository {
public:
    virtual ~ProfileRepository() = default;
    virtual std::vector<Profile> Fetch() = 0;
    virtual void Save(const Profile &profile) = 0;
    virtual void Remove(const std::string &id) = 0;
};
}
