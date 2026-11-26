// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../strategy/HttpClient.h"
#include <chrono>
#include <atomic>

namespace Passepartout::Windows {
class HttpClient final : public Passepartout::HttpClient {
public:
    explicit HttpClient(std::chrono::milliseconds timeout);
    std::string Get(const std::string &url) override;
    void Cancel() noexcept override;
private:
    template<typename Operation>
    auto Await(Operation operation, std::chrono::steady_clock::time_point deadline);
    std::chrono::milliseconds timeout_;
    std::atomic_bool canceled_{false};
};
}
