// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../strategy/ConfigManagerStrategy.h"
#include <memory>

namespace Passepartout {
class ConfigManager final {
public:
    ConfigManager(std::unique_ptr<ConfigManagerStrategy> strategy, int build);
    bool Refresh();
    const ConfigFlags &ActiveFlags() const;
    void Cancel() noexcept;
private:
    std::unique_ptr<ConfigManagerStrategy> strategy_;
    int build_;
    ConfigFlags flags_;
};
}
