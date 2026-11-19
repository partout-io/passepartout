// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <memory>
#include <optional>
#include <string>

namespace Passepartout {
// Start and poll on the foreground UI thread. Destruction cancels the request.
class WindowsURLLauncher final {
public:
    explicit WindowsURLLauncher(const std::string &url);
    ~WindowsURLLauncher();
    std::optional<bool> Poll();
private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};
}
