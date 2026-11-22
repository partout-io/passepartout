// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "FileProfileJournal.h"
#include "../extensions/AtomicFile.h"
#include <stdexcept>

namespace Passepartout {
FileProfileJournal::FileProfileJournal(std::filesystem::path directory)
    : directory_(std::move(directory)) {
    std::filesystem::create_directories(directory_);
#ifndef _WIN32
    std::filesystem::permissions(directory_, std::filesystem::perms::owner_all);
#endif
}
std::filesystem::path FileProfileJournal::Path(const std::string &id) const {
    if (!IsSafeProfileId(id)) throw std::runtime_error("Invalid transaction identity.");
    return directory_ / (id + ".json");
}
std::vector<ProfileTransaction> FileProfileJournal::Fetch() {
    std::vector<ProfileTransaction> result;
    for (const auto &entry : std::filesystem::directory_iterator(directory_)) {
        if (entry.path().extension() != ".json") continue;
        if (!entry.is_regular_file() || entry.is_symlink())
            throw std::runtime_error("Invalid transaction file.");
        try {
            const auto json = Partout::Models::Json::Parse(ReadConfiguration(entry.path()));
            if (json.At("version") != 1) throw std::runtime_error("Invalid transaction version.");
            if (json.Value("committed", false)) continue;
            ProfileTransaction transaction;
            transaction.id = json.At("id").Get<std::string>();
            transaction.removal = json.At("removal").Get<bool>();
            if (!json.At("previous").IsNull()) {
                transaction.previous = Profile::FromJson(json.At("previous"));
                ValidateProfileIdentity(*transaction.previous);
                if (transaction.previous->id != transaction.id)
                    throw std::runtime_error("Conflicting transaction identity.");
            }
            if (Path(transaction.id).filename() != entry.path().filename())
                throw std::runtime_error("Conflicting transaction path.");
            result.push_back(std::move(transaction));
        } catch (...) {
            throw std::runtime_error("Unable to read profile recovery data. Original files were preserved.");
        }
    }
    return result;
}
void FileProfileJournal::Save(const ProfileTransaction &transaction) {
    Partout::Models::Json json = {{"version", 1}, {"id", transaction.id},
        {"removal", transaction.removal}, {"previous", nullptr}};
    if (transaction.previous) json.Set("previous", transaction.previous->ToJson());
    const auto text = json.Encode();
    if (text.size() > MaxConfigurationBytes) throw std::runtime_error("Profile recovery data exceeds 1 MiB.");
    WriteAtomicFile(Path(transaction.id), text);
}
void FileProfileJournal::Remove(const std::string &id) {
    // Persist completion before deleting the record. If deletion is interrupted,
    // a completed update must never be mistaken for work requiring rollback.
    WriteAtomicFile(Path(id), Partout::Models::Json{{"version", 1}, {"committed", true}}.Encode());
    std::error_code ignored;
    std::filesystem::remove(Path(id), ignored);
}
}
