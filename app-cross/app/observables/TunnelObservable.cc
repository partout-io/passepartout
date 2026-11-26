// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "TunnelObservable.h"
#include "../context/AppLog.h"
#include <algorithm>

namespace Passepartout {
bool TunnelObservable::State::HasActivity() const {
    if (activity.foreground || pending_profile) return true;
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
    if (foreground) ClearOperationError();
    executor_.Post([this, operation = std::move(operation)] {
        try {
            operation();
            tunnel_->Advance();
        } catch (...) {
            AppLog::Write(AppLog::Level::error, AppLog::Category::tunnel, "Unable to execute VPN operation");
            std::lock_guard lock(mutex_);
            snapshot_.operation_error = "The VPN operation failed.";
        }
        Publish();
    }, foreground);
}

void TunnelObservable::Publish() {
    State state;
    try {
        state.tunnels = Tunnels::Info(tunnel_->Fetch());
        state.observation_errors = tunnel_->ObservationErrors();
        state.available = true;
    } catch (...) {
        state.observation_error = "Unable to read VPN state.";
    }
    state.pending_profile = tunnel_->PendingProfile();
    std::lock_guard lock(mutex_);
    state.operation_error = snapshot_.operation_error;
    state.revision = snapshot_.revision + 1;
    snapshot_ = std::move(state);
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
    if (!executor_.Snapshot().busy) Post([] {}, false);
}

void TunnelObservable::ClearOperationError() {
    std::lock_guard lock(mutex_);
    snapshot_.operation_error.clear();
    ++snapshot_.revision;
}

TunnelObservable::State TunnelObservable::Snapshot() const {
    const auto activity = executor_.Snapshot();
    std::lock_guard lock(mutex_);
    auto result = snapshot_;
    result.activity = activity;
    return result;
}
}
