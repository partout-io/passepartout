// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "credits_observable.h"
#include <algorithm>

namespace Passepartout {
CreditsObservable::CreditsObservable(std::string resource, std::unique_ptr<HttpClient> client)
    : client_(std::move(client)), worker_([this] {
        client_->Cancel();
    }) {
    try {
        auto json = nlohmann::json::parse(resource);
        // Applicability is resource metadata, not a second inventory in code.
        for (const auto *group : {"licenses", "notices"}) {
            auto selected = nlohmann::json::array();
            for (const auto &entry : json.at(group)) {
                if (entry.value("windows", true)) selected.push_back(entry);
            }
            for (const auto &entry : json.at("windows").at(group)) selected.push_back(entry);
            json[group] = std::move(selected);
        }
        credits_ = Models::Credits::FromJson(json);
        std::sort(credits_.licenses.begin(), credits_.licenses.end(), [](const auto &a, const auto &b) {
            return a.name < b.name;
        });
    } catch (...) {
        loadError_ = true;
    }
}
CreditsObservable::~CreditsObservable() {
    worker_.Stop();
}
const Models::Credits &CreditsObservable::Snapshot() const {
    return credits_;
}
bool CreditsObservable::HasLoadError() const {
    return loadError_;
}
CreditsObservable::Content CreditsObservable::License(const std::string &url) const {
    std::lock_guard lock(mutex_);
    const auto found = content_.find(url);
    return found == content_.end() ? Content{} : found->second;
}
void CreditsObservable::LoadLicense(const std::string &url) {
    if (std::none_of(credits_.licenses.begin(), credits_.licenses.end(), [&](const auto &license) {
        return license.licenseURL == url;
    })) return;
    std::lock_guard lock(mutex_);
    auto &content = content_[url];
    if (content.loading || !content.text.empty()) return;
    content.loading = true;
    worker_.Post([this, url] {
        Content result;
        try {
            result.text = client_->Get(url);
        } catch (...) {
            result.failed = true;
        }
        std::lock_guard lock(mutex_);
        content_[url] = std::move(result);
    });
}
}
