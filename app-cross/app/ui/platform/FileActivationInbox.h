// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../business/models/ConfigurationFiles.h"
#include <functional>
#include <set>

namespace Passepartout {
// A bounded, versioned activation message contains copied configuration content,
// never sender-owned files or handles whose lifetime could end before import.
class FileActivationInbox final {
public:
    using Handler = std::function<bool(std::shared_ptr<const ConfigurationFiles>)>;
    static constexpr std::size_t MaximumBytes = 64 * 1024 * 1024;
    static std::string Encode(const std::string &id, const ConfigurationFiles &files);
    bool Accept(const std::string &message, const Handler &handler);
private:
    std::set<std::string> accepted_;
};
}
