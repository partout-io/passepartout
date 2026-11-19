// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../models/Profile.h"
#include <map>
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
// Ephemeral journal for injected test repositories; production uses FileProfileJournal.
class MemoryProfileJournal final : public ProfileJournal {
public:
    std::vector<ProfileTransaction> Fetch() override;
    void Save(const ProfileTransaction &transaction) override;
    void Remove(const std::string &id) override;
private:
    std::map<std::string, ProfileTransaction> transactions_;
};
}
