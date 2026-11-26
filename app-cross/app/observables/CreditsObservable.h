// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/extensions/Models+Business.h"
#include "../business/strategy/HttpClient.h"
#include "Worker.h"
#include <map>

namespace Passepartout {
class CreditsObservable final {
public:
    struct Content final {
        std::string text;
        bool loading = false;
        bool operation_failed = false;
    };
    CreditsObservable(std::string resource, std::unique_ptr<HttpClient> client,
                      Models::Platform::ePlatform platform);
    const Models::Credits &Snapshot() const;
    bool HasLoadError() const;
    Content License(const std::string &url) const;
    void LoadLicense(const std::string &url);
private:
    Models::Credits credits_{};
    bool load_error_ = false;
    std::unique_ptr<HttpClient> client_;
    mutable std::mutex mutex_;
    std::map<std::string, Content> content_;
    // Destroy first: cancels and joins before captured state and dependencies.
    Worker worker_;
};
}
