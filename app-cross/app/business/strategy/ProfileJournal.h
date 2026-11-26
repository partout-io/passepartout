// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../extensions/Models+Business.h"
#include <optional>

namespace Passepartout {
struct ProfileTransaction {
    std::string id;
    std::optional<Profile> previous;
    bool removal = false;
};
class ProfileJournal {
public:
    virtual ~ProfileJournal() = default;
    virtual std::vector<ProfileTransaction> Fetch() = 0;
    virtual void Save(const ProfileTransaction &transaction) = 0;
    virtual void Remove(const std::string &id) = 0;
};
}
