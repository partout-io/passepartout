// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../strategy/ConfigManagerStrategy.h"
#include "Event.h"
#include <functional>
#include <map>
#include <memory>

namespace Passepartout {
class ConfigManager final {
public:
    using EventHandler = std::function<void(const Models::Event &)>;
    // Subscribe before starting work; unsubscribe after stopping it.
    std::size_t Subscribe(EventHandler handler);
    void Unsubscribe(std::size_t subscription);
    ConfigManager(std::unique_ptr<ConfigManagerStrategy> strategy, int build, Models::Platform::ePlatform platform);
    bool Refresh();
    const ConfigFlags &ActiveFlags() const;
    void Cancel() noexcept;
private:
    void Emit(const Models::Event &event);
    std::map<std::size_t, EventHandler> handlers_;
    std::size_t next_subscription_ = 0;
    std::unique_ptr<ConfigManagerStrategy> strategy_;
    int build_;
    Models::Platform::ePlatform platform_;
    ConfigFlags flags_;
};
}
