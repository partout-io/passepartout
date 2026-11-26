// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "FileActivationInbox.h"
#include <partout/Json.h>
#include <stdexcept>

namespace Passepartout {
std::string FileActivationInbox::Encode(const std::string &id, const ConfigurationFiles &files) {
    if (files.Count() > 64) throw std::runtime_error("Too many activation files.");
    auto sources = Partout::Json::Array();
    std::size_t failures = files.selection_failures;
    std::size_t encoded_bytes = 1024;
    for (std::size_t index = 0; index < files.Count(); ++index) {
        try {
            const auto source = files.Read(index);
            if (source.text.empty() || source.text.size() > 1024 * 1024 || source.name.size() > 4096)
                throw std::runtime_error("Invalid activation file.");
            const Partout::Json entry = {{"name", source.name}, {"text", source.text}};
            const auto size = entry.Encode().size(); // Validate UTF-8 independently for mixed batches.
            if (encoded_bytes + size + 1 > MaximumBytes) throw std::runtime_error("Activation is too large.");
            encoded_bytes += size + 1;
            sources.Append(entry);
        } catch (...) {
            ++failures;
        }
    }
    auto result = Partout::Json{{"version", 1}, {"id", id}, {"files", sources}, {"failures", failures}}.Encode();
    if (result.size() > MaximumBytes) throw std::runtime_error("Activation is too large.");
    return result;
}

bool FileActivationInbox::Accept(const std::string &message, const Handler &handler) {
    if (message.size() > MaximumBytes) return false;
    try {
        const auto json = Partout::Json::Parse(message);
        if (json.At("version") != 1) return false;
        const auto id = json.At("id").Get<std::string>();
        if (id.empty() || id.size() > 128) return false;
        if (accepted_.count(id)) return true;
        const auto &files = json.At("files");
        if (!files.IsArray() || files.Size() > 64) return false;
        const auto failures = json.At("failures").Get<std::size_t>();
        if (failures > 64 || files.Size() > 64 - failures) return false;
        std::vector<ConfigurationSource> sources;
        for (const auto &file : files.Elements()) {
            ConfigurationSource source{file.At("name").Get<std::string>(), file.At("text").Get<std::string>()};
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
