// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ProfileRepository.h"

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
    const std::filesystem::path objects_directory_;
    const std::filesystem::path index_file_;
};
}
