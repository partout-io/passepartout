// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "MainThread.h"
#include "../business/extensions/EventEmitter.h"
#include "../business/extensions/Models+Business.h"
#include "../business/strategy/HttpClient.h"
#include "Worker.h"
#include <map>

namespace Passepartout {
class CreditsObservable final {
public:
    EventEmitter<> changes;
    struct Content final {
        std::string text;
        bool loaded = false;
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
    MainThread delivery_;
    Models::Credits credits_{};
    bool load_error_ = false;
    std::unique_ptr<HttpClient> client_;
    std::map<std::string, Content> content_;
    // Destroy first: cancels and joins before captured state and dependencies.
    Worker worker_;
};
}
