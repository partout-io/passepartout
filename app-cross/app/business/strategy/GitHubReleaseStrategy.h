// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "VersionCheckerStrategy.h"
#include "HttpClient.h"
#include <functional>

namespace Passepartout {
class GitHubReleaseStrategy final : public VersionCheckerStrategy {
public:
    GitHubReleaseStrategy(std::unique_ptr<HttpClient> client, std::string release_url,
                          std::function<std::string(const std::string &)> changelog_url
    );
    std::string LatestVersion() override;
    std::vector<Models::ChangelogEntry> FetchChangelog(const std::string &build) override;
    void Cancel() noexcept override;
private:
    std::unique_ptr<HttpClient> client_;
    std::string release_url_;
    std::function<std::string(const std::string &)> changelog_url_;
};
}
