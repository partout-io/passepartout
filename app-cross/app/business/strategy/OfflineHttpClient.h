// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "HttpClient.h"

namespace Passepartout {
class OfflineHttpClient final : public HttpClient {
public:
    std::string Get(const std::string &url) override;
    void Cancel() noexcept override;
};
}
