// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ProfileJournal.h"

namespace Passepartout {
class FileProfileJournal final : public ProfileJournal {
public:
    explicit FileProfileJournal(std::filesystem::path directory);
    std::vector<ProfileTransaction> Fetch() override;
    void Save(const ProfileTransaction &transaction) override;
    void Remove(const std::string &id) override;
private:
    std::filesystem::path Path(const std::string &id) const;
    std::filesystem::path directory_;
};
}
