// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "ProfileJournal.h"

namespace Passepartout {
std::vector<ProfileTransaction> MemoryProfileJournal::Fetch() {
    std::vector<ProfileTransaction> result;
    for (const auto &[id, transaction] : transactions_) result.push_back(transaction);
    return result;
}
void MemoryProfileJournal::Save(const ProfileTransaction &transaction) {
    transactions_[transaction.id] = transaction;
}
void MemoryProfileJournal::Remove(const std::string &id) {
    transactions_.erase(id);
}
}
