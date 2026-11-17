// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "file_activation.h"
#include <partout/json.h>
#include <stdexcept>

namespace Passepartout {
std::string FileActivation::Encode(const std::string &id, const ConfigurationFiles &files) {
    if (files.Count() > 64) throw std::runtime_error("Too many activation files.");
    auto sources = nlohmann::json::array();
    std::size_t failures = files.selectionFailures;
    std::size_t encodedBytes = 1024;
    for (std::size_t index = 0; index < files.Count(); ++index) {
        try {
            const auto source = files.Read(index);
            if (source.text.empty() || source.text.size() > 1024 * 1024 || source.name.size() > 4096)
                throw std::runtime_error("Invalid activation file.");
            const nlohmann::json entry = {{"name", source.name}, {"text", source.text}};
            const auto size = entry.dump().size(); // Validate UTF-8 independently for mixed batches.
            if (encodedBytes + size + 1 > MaximumBytes) throw std::runtime_error("Activation is too large.");
            encodedBytes += size + 1;
            sources.push_back(entry);
        } catch (...) {
            ++failures;
        }
    }
    auto result = nlohmann::json{{"version", 1}, {"id", id}, {"files", sources}, {"failures", failures}}.dump();
    if (result.size() > MaximumBytes) throw std::runtime_error("Activation is too large.");
    return result;
}
bool FileActivation::Accept(const std::string &message, const Handler &handler) {
    if (message.size() > MaximumBytes) return false;
    try {
        const auto json = nlohmann::json::parse(message);
        if (json.at("version") != 1) return false;
        const auto id = json.at("id").get<std::string>();
        if (id.empty() || id.size() > 128) return false;
        if (accepted_.count(id)) return true;
        const auto &files = json.at("files");
        if (!files.is_array() || files.size() > 64) return false;
        const auto failures = json.at("failures").get<std::size_t>();
        if (failures > 64 || files.size() > 64 - failures) return false;
        std::vector<ConfigurationSource> sources;
        for (const auto &file : files) {
            ConfigurationSource source{file.at("name").get<std::string>(), file.at("text").get<std::string>()};
            if (source.name.size() > 4096 || source.text.size() > 1024 * 1024) return false;
            sources.push_back(std::move(source));
        }
        accepted_.insert(id);
        try {
            if (handler(std::make_shared<MemoryConfigurationFiles>(std::move(sources), failures))) return true;
        } catch (...) {}
        accepted_.erase(id);
        return false;
    } catch (...) {
        return false;
    }
}
}
