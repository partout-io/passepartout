// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "TunnelObservable.h"
#include "../context/AppLog.h"
#include <algorithm>

namespace Passepartout {
bool TunnelObservable::State::HasActivity() const {
    if (busy || pending_profile) return true;
    return available && std::any_of(tunnels.begin(), tunnels.end(), [](const auto &tunnel) {
        return tunnel.status.value == Status::connecting || tunnel.status.value == Status::disconnecting;
    });
}

TunnelObservable::TunnelObservable(
    Worker &executor, std::unique_ptr<Partout::Tunnel> tunnel, ProfileManager &profiles
) : profiles_(profiles),
    profile_subscription_(profiles.events.Subscribe([this](const Models::Event &event) { OnUpdate(event); })),
    executor_(executor), tunnel_(std::move(tunnel)) {}

TunnelObservable::~TunnelObservable() {
    profiles_.events.Unsubscribe(profile_subscription_);
}

void TunnelObservable::OnUpdate(const Models::Event &event) {
    const auto *deleted = std::get_if<Models::ProfileEventDelete>(&event);
    if (!deleted) return;
    for (const auto &id : deleted->ids) Remove(id);
}

void TunnelObservable::Cancel() {
    tunnel_->Cancel();
}

void TunnelObservable::Post(std::function<void()> operation, bool foreground) {
    if (foreground) {
        std::lock_guard lock(mutex_);
        snapshot_.errors.operation = false;
        snapshot_.busy = true;
        ++pending_operations_;
        changes.Emit();
    }
    const auto accepted = executor_.Post([this, operation = std::move(operation), foreground] {
        try {
            operation();
            tunnel_->Advance();
        } catch (...) {
            AppLog::Write(AppLog::Level::error, AppLog::Category::tunnel, "Unable to execute VPN operation");
            std::lock_guard lock(mutex_);
            snapshot_.errors.operation = true;
        }
        Publish();
        if (foreground) FinishOperation();
    }, foreground);
    if (!accepted && foreground) FinishOperation();
}

void TunnelObservable::FinishOperation() {
    std::lock_guard lock(mutex_);
    snapshot_.busy = --pending_operations_ != 0;
    changes.Emit();
}

void TunnelObservable::Publish() {
    State state;
    try {
        state.tunnels = Tunnels::Info(tunnel_->Fetch());
        for (const auto &[id, error] : tunnel_->ObservationErrors()) state.errors.unobservable_profiles.insert(id);
        state.available = true;
    } catch (...) {
        state.available = false;
    }
    state.pending_profile = tunnel_->PendingProfile();
    std::lock_guard lock(mutex_);
    state.errors.operation = snapshot_.errors.operation;
    state.busy = snapshot_.busy;
    snapshot_ = std::move(state);
    changes.Emit();
}

std::optional<InteractiveLogin> TunnelObservable::Connect(
    Profile profile, std::optional<Partout::TunnelCredentials> credentials
) {
    if (!credentials) {
        auto login = Profiles::InteractiveLoginFor(profile);
        if (login) return login;
    }
    Post([this, profile = std::move(profile), credentials = std::move(credentials)] {
        tunnel_->Connect(profile, credentials);
    });
    return {};
}

void TunnelObservable::Disconnect(std::string id) {
    Post([this, id = std::move(id)] {
        tunnel_->Disconnect(id);
    });
}

void TunnelObservable::Remove(std::string id) {
    Post([this, id = std::move(id)] {
        tunnel_->Remove(id);
    });
}

void TunnelObservable::Refresh() {
    if (!executor_.CurrentActivity().busy) Post([] {}, false);
}

void TunnelObservable::ClearOperationError() {
    std::lock_guard lock(mutex_);
    snapshot_.errors.operation = false;
    changes.Emit();
}

TunnelObservable::State TunnelObservable::Snapshot() const {
    std::lock_guard lock(mutex_);
    auto result = snapshot_;
    if (executor_.IsStopping()) result.busy = false;
    return result;
}

}
