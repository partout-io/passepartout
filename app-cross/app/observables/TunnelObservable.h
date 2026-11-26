// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/models/AppSnapshot.h"
#include "../business/models/InteractiveLogin.h"

namespace Passepartout {
class AppSession;

class TunnelObservable final {
public:
    struct ToggleState {
        bool is_on = false;
        bool can_interact = false;
        Status status = Status::disconnected;
    };
    explicit TunnelObservable(AppSession &session) : session_(session) {}
    static ToggleState StateForProfile(const AppSnapshot &state, const std::string &id);
    void SetEnabled(const std::string &id, bool enabled);
    void Connect(std::string id);
    std::optional<InteractiveLogin> TakeInteractiveLogin();
    void CompleteInteractiveLogin(InteractiveLogin login);
    void Disconnect(std::string id);
    void Refresh();
    AppSnapshot Snapshot() const;
private:
    AppSession &session_;
    std::optional<InteractiveLogin> interactive_login_;
};
}
