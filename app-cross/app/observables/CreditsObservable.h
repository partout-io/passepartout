// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/extensions/ModelsExtensions.h"
#include "../business/strategy/HttpClient.h"
#include "../business/extensions/BackgroundWorker.h"
#include <map>

namespace Passepartout {
class CreditsObservable {
public:
    struct Content {
        std::string text;
        bool loading = false;
        bool failed = false;
    };
    CreditsObservable(std::string resource, std::unique_ptr<HttpClient> client,
                      Models::Platform::ePlatform platform = Credits::CurrentPlatform());
    ~CreditsObservable();
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
    BackgroundWorker worker_;
};
}
