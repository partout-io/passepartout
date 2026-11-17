// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "profile_repository.h"

namespace Passepartout {
class FileProfileRepository final : public ProfileRepository {
public:
    explicit FileProfileRepository(std::filesystem::path directory);
    std::vector<Profile> Fetch() override;
    void Save(const Profile &profile) override;
    void Remove(const std::string &id) override;
private:
    std::filesystem::path ObjectPath(const std::string &id) const;
    std::vector<Profile> ReadObjects();
    void PersistIndex(const std::vector<Profile> &profiles);
    std::filesystem::path root_;
    std::filesystem::path directory_;
};
}
