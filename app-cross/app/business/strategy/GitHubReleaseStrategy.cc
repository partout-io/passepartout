// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "GitHubReleaseStrategy.h"
#include "../extensions/Models+Business.h"
#include <partout/Json.h>
#include <stdexcept>

namespace Passepartout {
GitHubReleaseStrategy::GitHubReleaseStrategy(std::unique_ptr<HttpClient> client, std::string release_url,
                                             std::function<std::string(const std::string &)> changelog_url
)
    : client_(std::move(client)), release_url_(std::move(release_url)), changelog_url_(std::move(changelog_url)) {}

std::string GitHubReleaseStrategy::LatestVersion() {
    const auto release = Partout::Json::Parse(client_->Get(release_url_));
    if (!release.IsObject()) throw std::runtime_error("Invalid release response.");
    const auto name = release.Find("name");
    if (!name || !name->IsString()) throw std::runtime_error("Invalid release response.");
    // Apple and Android use the release name, not tag_name. VersionChecker
    // validates and compares the version before exposing an update.
    return name->Get<std::string>();
}

std::vector<Models::ChangelogEntry> GitHubReleaseStrategy::FetchChangelog(const std::string &build) {
    return Changelogs::Parse(client_->Get(changelog_url_(build)));
}

void GitHubReleaseStrategy::Cancel() noexcept {
    client_->Cancel();
}
}
