// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../strategy/ConfigManagerStrategy.h"
#include <memory>
#include "ConfigBundleConfig.h"
#include "ConfigFlag.h"
#include <map>

namespace Passepartout {
class ConfigManager final {
public:
    using Flags = std::map<Models::ConfigFlag::eConfigFlag, Partout::Json>;
    ConfigManager(std::unique_ptr<ConfigManagerStrategy> strategy, int build);
    bool Refresh();
    const Flags &ActiveFlags() const;
    void Cancel() noexcept;
private:
    std::unique_ptr<ConfigManagerStrategy> strategy_;
    int build_;
    Flags flags_;
};
}
