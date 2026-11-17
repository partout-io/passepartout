// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <memory>
#include <string>

namespace Passepartout {
class HttpClient {
public:
    virtual ~HttpClient() = default;
    virtual std::string Get(const std::string &url) = 0;
    // Permanent cancellation, callable from the owner's shutdown thread.
    virtual void Cancel() noexcept = 0;
};
}
