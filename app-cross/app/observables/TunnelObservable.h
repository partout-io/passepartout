// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppSnapshot.h"
#include "InteractiveLogin.h"
#include "../business/ConfigurationFiles.h"

namespace Passepartout {
class AppSession;

class TunnelObservable {
public:
    struct ToggleState {
        bool isOn = false;
        bool canInteract = false;
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
    std::optional<InteractiveLogin> interactiveLogin_;
};
}
