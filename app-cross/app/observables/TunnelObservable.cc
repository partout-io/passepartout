// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "TunnelObservable.h"
#include "../context/AppLog.h"
#include <algorithm>

namespace {
Passepartout::TunnelObservable::State ReadState(Partout::Tunnel &tunnel) {
    Passepartout::TunnelObservable::State state;
    try {
        state.tunnels = Passepartout::Tunnels::Info(tunnel.Fetch());
        for (const auto &[id, error] : tunnel.ObservationErrors()) state.errors.unobservable_profiles.insert(id);
        state.available = true;
    } catch (...) {
        state.available = false;
    }
    state.pending_profile = tunnel.PendingProfile();
    return state;
}
}

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
    profile_subscription_(profiles.events.Subscribe([this](const Models::Event &event) {
        delivery_.Post([this, event] { OnUpdate(event); });
    })),
    executor_(executor), tunnel_(std::move(tunnel)) {}

TunnelObservable::~TunnelObservable() {
    MainThread::Assert();
    profiles_.events.Unsubscribe(profile_subscription_);
}

void TunnelObservable::OnUpdate(const Models::Event &event) {
    MainThread::Assert();
    const auto *deleted = std::get_if<Models::ProfileEventDelete>(&event);
    if (!deleted) return;
    for (const auto &id : deleted->ids) Remove(id);
}

void TunnelObservable::Cancel() {
    MainThread::Assert();
    tunnel_->Cancel();
}

void TunnelObservable::Post(std::function<void()> operation, bool foreground) {
    MainThread::Assert();
    if (foreground) {
        snapshot_.errors.operation = false;
        snapshot_.busy = true;
        ++pending_operations_;
        changes.Emit();
    }
    const auto accepted = executor_.Post([this, operation = std::move(operation), foreground] {
        bool failed = false;
        try {
            operation();
            tunnel_->Advance();
        } catch (...) {
            AppLog::Write(AppLog::Level::error, AppLog::Category::tunnel, "Unable to execute VPN operation");
            failed = true;
        }
        auto state = ReadState(*tunnel_);
        delivery_.Post([this, state = std::move(state), failed, foreground]() mutable {
            state.errors.operation = snapshot_.errors.operation || failed;
            state.busy = snapshot_.busy;
            snapshot_ = std::move(state);
            if (foreground) FinishOperation();
            else changes.Emit();
        });
    }, foreground);
    if (!accepted && foreground) FinishOperation();
}

void TunnelObservable::FinishOperation() {
    MainThread::Assert();
    snapshot_.busy = --pending_operations_ != 0;
    changes.Emit();
}


std::optional<InteractiveLogin> TunnelObservable::Connect(
    Profile profile, std::optional<Partout::TunnelCredentials> credentials
) {
    MainThread::Assert();
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
    MainThread::Assert();
    Post([this, id = std::move(id)] {
        tunnel_->Disconnect(id);
    });
}

void TunnelObservable::Remove(std::string id) {
    MainThread::Assert();
    Post([this, id = std::move(id)] {
        tunnel_->Remove(id);
    });
}

void TunnelObservable::Refresh() {
    MainThread::Assert();
    if (!executor_.CurrentActivity().busy) Post([] {}, false);
}

void TunnelObservable::ClearOperationError() {
    MainThread::Assert();
    snapshot_.errors.operation = false;
    changes.Emit();
}

TunnelObservable::State TunnelObservable::Snapshot() const {
    MainThread::Assert();
    auto result = snapshot_;
    if (executor_.IsStopping()) result.busy = false;
    return result;
}

}
