// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "VersionCheckerStrategy.h"
#include "HttpClient.h"

namespace Passepartout {
class GitHubReleaseStrategy final : public VersionCheckerStrategy {
public:
    GitHubReleaseStrategy(std::unique_ptr<HttpClient> client, std::string release_url);
    std::string LatestVersion() override;
    void Cancel() noexcept override;
private:
    std::unique_ptr<HttpClient> client_;
    std::string release_url_;
};
}
