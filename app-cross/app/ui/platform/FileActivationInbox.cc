// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "../../business/models/MemoryConfigurationFiles.h"
#include "FileActivationInbox.h"
#include <partout/Json.h>
#include <stdexcept>

namespace {
constexpr int MessageVersion = 1;
constexpr std::size_t MaximumFiles = 64;
constexpr std::size_t MaximumContentBytes = 1024 * 1024;
constexpr std::size_t MaximumNameBytes = 4096;
constexpr std::size_t MaximumIdBytes = 128;
// Reserve space for envelope fields and count the comma between encoded files.
constexpr std::size_t EnvelopeByteAllowance = 1024;
constexpr std::size_t EntrySeparatorBytes = 1;

namespace MessageFields {
constexpr const char Version[] = "version";
constexpr const char Id[] = "id";
constexpr const char Files[] = "files";
constexpr const char Failures[] = "failures";
constexpr const char Name[] = "name";
constexpr const char Text[] = "text";
}
}

namespace Passepartout {
std::string FileActivationInbox::Encode(const std::string &id, const ConfigurationFiles &files) {
    if (files.Count() > MaximumFiles) throw std::runtime_error("Too many activation files.");
    auto sources = Partout::Json::Array();
    std::size_t failures = files.SelectionFailures();
    std::size_t encoded_bytes = EnvelopeByteAllowance;
    for (std::size_t index = 0; index < files.Count(); ++index) {
        try {
            const auto source = files.Read(index);
            if (source.text.empty() || source.text.size() > MaximumContentBytes || source.name.size() > MaximumNameBytes)
                throw std::runtime_error("Invalid activation file.");
            const Partout::Json entry = {{MessageFields::Name, source.name}, {MessageFields::Text, source.text}};
            const auto size = entry.Encode().size(); // Validate UTF-8 independently for mixed batches.
            if (encoded_bytes + size + EntrySeparatorBytes > MaximumBytes) throw std::runtime_error("Activation is too large.");
            encoded_bytes += size + EntrySeparatorBytes;
            sources.Append(entry);
        } catch (...) {
            ++failures;
        }
    }
    auto result = Partout::Json{{MessageFields::Version, MessageVersion}, {MessageFields::Id, id}, {MessageFields::Files, sources}, {MessageFields::Failures, failures}}.Encode();
    if (result.size() > MaximumBytes) throw std::runtime_error("Activation is too large.");
    return result;
}

bool FileActivationInbox::Accept(const std::string &message, const Handler &handler) {
    if (message.size() > MaximumBytes) return false;
    try {
        const auto json = Partout::Json::Parse(message);
        if (json.At(MessageFields::Version) != MessageVersion) return false;
        const auto id = json.At(MessageFields::Id).Get<std::string>();
        if (id.empty() || id.size() > MaximumIdBytes) return false;
        if (accepted_.count(id)) return true;
        const auto &files = json.At(MessageFields::Files);
        if (!files.IsArray() || files.Size() > MaximumFiles) return false;
        const auto failures = json.At(MessageFields::Failures).Get<std::size_t>();
        if (failures > MaximumFiles || files.Size() > MaximumFiles - failures) return false;
        std::vector<ConfigurationSource> sources;
        for (const auto &file : files.Elements()) {
            ConfigurationSource source{file.At(MessageFields::Name).Get<std::string>(), file.At(MessageFields::Text).Get<std::string>()};
            if (source.name.size() > MaximumNameBytes || source.text.size() > MaximumContentBytes) return false;
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
