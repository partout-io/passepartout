// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "TunnelObservable.h"
#include "../context/AppLog.h"
#include <algorithm>
#include <stdexcept>

namespace Passepartout {
bool TunnelObservable::State::HasActivity() const {
    if (activity.foreground || pending_profile) return true;
    return available && std::any_of(tunnels.begin(), tunnels.end(), [](const auto &tunnel) {
        return tunnel.status.value == Status::connecting || tunnel.status.value == Status::disconnecting;
    });
}

TunnelObservable::TunnelObservable(Worker &executor, std::unique_ptr<Partout::Tunnel> tunnel,
                                   std::function<void(const Models::AppPreferences &)> apply_preferences
) : executor_(executor), tunnel_(std::move(tunnel)),
    apply_preferences_(std::move(apply_preferences)) {
}

void TunnelObservable::Cancel() {
    tunnel_->Cancel();
}

void TunnelObservable::SetProfiles(std::vector<Profile> profiles, bool loaded) {
    Post([this, profiles = std::move(profiles), loaded] {
        std::lock_guard lock(mutex_);
        profiles_ = profiles;
        snapshot_.profiles_loaded = loaded;
        snapshot_.profile_ids.clear();
        for (const auto &profile : profiles_) {
            snapshot_.profile_ids.push_back(profile.id);
        }
        if (pending_profile_ && std::none_of(profiles_.begin(), profiles_.end(), [&](const auto &profile) {
            return profile.id == *pending_profile_;
        })) pending_profile_.reset();
    }, false, true);
}

void TunnelObservable::ApplyPreferences(Models::AppPreferences preferences) {
    Post([this, preferences = std::move(preferences)] {
        pending_preferences_ = preferences;
        ApplyPendingPreferences();
    });
}

bool TunnelObservable::ProfilesLoaded() const {
    std::lock_guard lock(mutex_);
    return snapshot_.profiles_loaded;
}

void TunnelObservable::ApplyPendingPreferences() {
    if (!pending_preferences_) return;
    if (apply_preferences_) apply_preferences_(*pending_preferences_);
    pending_preferences_.reset();
}

bool TunnelObservable::Post(std::function<void()> operation, bool foreground, bool dispatch) {
    if (foreground) ClearOperationError();
    auto task = [this, operation = std::move(operation)] {
        std::string error;
        try {
            operation();
            tunnel_->Advance();
        } catch (const std::exception &failure) {
            error = failure.what();
            pending_profile_.reset();
        } catch (...) {
            error = "The VPN operation failed.";
            pending_profile_.reset();
        }
        if (!error.empty()) AppLog::Write(AppLog::Level::error, AppLog::Category::tunnel, "Unable to execute VPN operation");
        {
            std::lock_guard lock(mutex_);
            if (!error.empty()) {
                snapshot_.operation_error = std::move(error);
            }
            ++snapshot_.revision;
        }
        Observe();
    };
    return dispatch ? executor_.Dispatch(std::move(task), foreground) : executor_.Post(std::move(task), foreground);
}

void TunnelObservable::Observe() {
    std::string error;
    try {
        Publish();
    } catch (const std::exception &failure) {
        error = failure.what();
    } catch (...) {
        error = "Unable to read VPN state.";
    }
    if (error != last_observation_error_) {
        AppLog::Write(error.empty() ? AppLog::Level::info : AppLog::Level::error, AppLog::Category::tunnel,
            error.empty() ? "Tunnel observation recovered" : "Unable to fetch tunnel state");
        last_observation_error_ = error;
    }
    std::lock_guard lock(mutex_);
    if (!error.empty()) snapshot_.available = false;
    snapshot_.pending_profile = pending_profile_;
    snapshot_.observation_error = std::move(error);
    ++snapshot_.revision;
}

std::string TunnelObservable::SynchronizeProfiles(const std::vector<Models::AppTunnelInfo> &tunnels, bool &changed) {
    if (!ProfilesLoaded()) return {};
    const auto unavailable = tunnel_->ObservationErrors();
    std::string error;
    for (const auto &profile : profiles_) {
        if (unavailable.count(profile.id)) continue;
        const auto native = std::find_if(tunnels.begin(), tunnels.end(), [&](const auto &value) {
            return value.id == profile.id;
        });
        // Preserve a running connection; apply saved edits after it disconnects.
        if (native != tunnels.end() && (native->isEnabled || native->status.value != Status::disconnected)) continue;
        const auto synchronized = synchronized_profiles_.find(profile.id);
        if (native != tunnels.end() && synchronized != synchronized_profiles_.end() && synchronized->second == profile) continue;
        try {
            changed = true;
            tunnel_->Save(profile);
            synchronized_profiles_[profile.id] = profile;
        } catch (...) {
            error = "Unable to synchronize saved VPN profile " + profile.id + ".";
        }
    }
    // Fetch exposes only this app's registrations. Never clean up after a failed local load.
    for (const auto &native : tunnels) {
        if (unavailable.count(native.id)) continue;
        const bool exists = std::any_of(profiles_.begin(), profiles_.end(), [&](const auto &profile) {
            return profile.id == native.id;
        });
        if (exists) continue;
        try {
            changed = true;
            tunnel_->Remove(native.id);
            synchronized_profiles_.erase(native.id);
        } catch (...) {
            error = "Unable to remove VPN registration " + native.id + ".";
        }
    }
    return error;
}

void TunnelObservable::Publish() {
    auto tunnels = Tunnels::Info(tunnel_->Fetch());
    bool changed = false;
    auto synchronization_error = SynchronizeProfiles(tunnels, changed);
    if (changed) tunnels = Tunnels::Info(tunnel_->Fetch());
    if (synchronization_error != last_synchronization_error_) {
        AppLog::Write(synchronization_error.empty() ? AppLog::Level::info : AppLog::Level::error, AppLog::Category::profiles,
            synchronization_error.empty() ? "Profile synchronization succeeded" : synchronization_error);
        last_synchronization_error_ = synchronization_error;
    }
    const auto previous = Snapshot();
    const auto observation_errors = tunnel_->ObservationErrors();
    for (const auto &[id, error] : observation_errors) {
        const auto old = previous.observation_errors.find(id);
        if (old == previous.observation_errors.end() || old->second != error)
            AppLog::Write(AppLog::Level::error, AppLog::Category::tunnel, "Unable to observe profile " + id + ": " + error);
    }
    for (const auto &[id, error] : previous.observation_errors) {
        if (observation_errors.find(id) == observation_errors.end())
            AppLog::Write(AppLog::Level::info, AppLog::Category::tunnel, "Profile observation error cleared: " + id);
    }
    for (const auto &tunnel : tunnels) {
        const auto old = std::find_if(previous.tunnels.begin(), previous.tunnels.end(), [&](const auto &value) {
            return value.id == tunnel.id;
        });
        if (old == previous.tunnels.end() || old->status != tunnel.status)
            AppLog::Write(AppLog::Level::info, AppLog::Category::tunnel, "Profile " + tunnel.id + " status: " + tunnel.status.ToJson().Encode());
    }
    // The requested target is presentation state; Partout owns the handover.
    if (pending_profile_ && std::any_of(tunnels.begin(), tunnels.end(), [&](const auto &tunnel) {
        return tunnel.id == *pending_profile_ && tunnel.status.value == Status::connected;
    })) pending_profile_.reset();
    std::lock_guard lock(mutex_);
    snapshot_.pending_profile = pending_profile_;
    snapshot_.tunnels = std::move(tunnels);
    snapshot_.available = true;
    snapshot_.observation_errors = observation_errors;
    snapshot_.synchronization_error = std::move(synchronization_error);
}

void TunnelObservable::Connect(std::string id) {
    if (interactive_login_) return;
    {
        std::lock_guard lock(mutex_);
        if (!snapshot_.profiles_loaded) return;
        const auto found = std::find_if(profiles_.begin(), profiles_.end(), [&](const auto &profile) {
            return profile.id == id;
        });
        if (found == profiles_.end()) return;
        interactive_login_ = Profiles::InteractiveLoginFor(*found);
    }
    if (!interactive_login_) ConnectProfile(std::move(id));
}

TunnelObservable::ToggleState TunnelObservable::StateForProfile(const State &state, const std::string &id) {
    ToggleState result;
    for (const auto &tunnel : state.tunnels) {
        if (tunnel.id == id) {
            result.is_on = tunnel.isEnabled;
            result.status = tunnel.status.value;
        }
    }
    const bool exists = std::any_of(state.profile_ids.begin(), state.profile_ids.end(), [&](const auto &profile_id) {
        return profile_id == id;
    });
    result.can_interact = exists && state.profiles_loaded && !state.activity.foreground && !state.pending_profile && state.available &&
        state.observation_errors.find(id) == state.observation_errors.end() &&
        result.status != Status::disconnecting;
    return result;
}

void TunnelObservable::SetEnabled(const std::string &id, bool enabled) {
    const auto state = StateForProfile(Snapshot(), id);
    if (!state.can_interact || state.is_on == enabled) return;
    if (enabled) Connect(id);
    else Disconnect(id);
}

std::optional<InteractiveLogin> TunnelObservable::TakeInteractiveLogin() {
    auto login = std::move(interactive_login_);
    interactive_login_.reset();
    return login;
}

void TunnelObservable::CompleteInteractiveLogin(InteractiveLogin login) {
    if (!login.CanSubmit() || !StateForProfile(Snapshot(), login.original.id).can_interact) return;
    const auto id = login.original.id;
    ConnectProfile(id, std::move(login.credentials));
}

void TunnelObservable::ConnectProfile(std::string id, std::optional<Partout::TunnelCredentials> credentials) {
    Post([this, id = std::move(id), credentials = std::move(credentials)] {
        ApplyPendingPreferences();
        if (!ProfilesLoaded()) throw std::runtime_error("Load the saved profiles before connecting.");
        const auto found = std::find_if(profiles_.begin(), profiles_.end(), [&](const auto &profile) {
            return profile.id == id;
        });
        if (found == profiles_.end()) throw std::runtime_error("The profile no longer exists.");
        const auto profile = *found;
        pending_profile_.reset();
        const auto native = tunnel_->Fetch();
        const bool already_active = std::any_of(native.begin(), native.end(), [&](const auto &value) {
            return value.id == id && value.status.value == Partout::Models::TunnelStatus::active;
        });
        const auto synchronized = synchronized_profiles_.find(id);
        const bool installed = std::any_of(native.begin(), native.end(), [&](const auto &value) {
            return value.id == id;
        });
        if (!already_active && (!installed || synchronized == synchronized_profiles_.end() || synchronized->second != profile)) {
            // Never connect using an older native configuration after a synchronization failure.
            tunnel_->Save(profile);
            synchronized_profiles_[id] = profile;
        }
        tunnel_->Connect(profile, std::move(credentials));
        pending_profile_ = id;
    });
}

void TunnelObservable::Disconnect(std::string id) {
    Post([this, id = std::move(id)] {
        pending_profile_.reset();
        tunnel_->Disconnect(id);
    });
}

void TunnelObservable::Refresh() {
    const auto state = Snapshot();
    if (state.activity.busy || !state.operation_error.empty()) return;
    Post([] {}, false);
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
