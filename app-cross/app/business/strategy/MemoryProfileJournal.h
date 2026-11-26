// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ProfileJournal.h"
#include <map>

namespace Passepartout {
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
