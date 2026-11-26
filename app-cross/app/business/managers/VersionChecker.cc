// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "VersionChecker.h"
#include <array>
#include <charconv>
#include <stdexcept>

namespace {
std::optional<std::array<unsigned, 4>> Parse(const std::string &text) {
    std::array<unsigned, 4> parts{};
    std::size_t start = 0;
    for (std::size_t i = 0; i < parts.size(); ++i) {
        const auto end = text.find('.', start);
        const auto limit = end == std::string::npos ? text.size() : end;
        if (start == limit) return {};
        const auto parsed = std::from_chars(text.data() + start, text.data() + limit, parts[i]);
        if (parsed.ec != std::errc() || parsed.ptr != text.data() + limit) return {};
        if (end == std::string::npos) return i >= 2 ? std::optional(parts) : std::nullopt;
        start = end + 1;
    }
    return {};
}
}

using Passepartout::VersionChecker;

VersionChecker::VersionChecker(std::string current, std::unique_ptr<VersionCheckerStrategy> strategy,
    std::string destination, std::int64_t rate_limit_seconds, std::optional<std::int64_t> last_checked,
    std::optional<std::string> cached, SaveVersion save)
    : current_(std::move(current)), strategy_(std::move(strategy)), destination_(std::move(destination)),
      rate_limit_seconds_(rate_limit_seconds), last_checked_(last_checked), cached_(std::move(cached)), save_(std::move(save)) {}

bool VersionChecker::Available() const {
    return strategy_ && destination_.compare(0, 8, "https://") == 0;
}

VersionChecker::State VersionChecker::Snapshot() const {
    State state;
    if (!Available() || !cached_) return state;
    const auto current = Parse(current_);
    const auto latest = Parse(*cached_);
    if (current && latest && *latest > *current) {
        state.latest = cached_;
        state.download_url = destination_;
    }
    return state;
}

void VersionChecker::Check(std::int64_t now) {
    if (!Available()) return;
    if (last_checked_ && now >= *last_checked_ && (now - *last_checked_) / 1000 < rate_limit_seconds_) {
        PublishRelease();
        return;
    }
    // Network failures leave the last successful result intact. Malformed
    // releases clear it, so a stale release is never offered as a fresh result.
    const auto latest = strategy_->LatestVersion();
    const auto parsed = Parse(latest);
    const std::optional<std::string> value = parsed ? std::optional(latest) : std::nullopt;
    save_(now, value);
    last_checked_ = now;
    cached_ = value;
    if (!parsed) throw std::runtime_error("Invalid release version.");
    PublishRelease();
}

void VersionChecker::PublishRelease() {
    const auto state = Snapshot();
    if (!state.latest) return;
    const auto version = Parse(*state.latest);
    Models::VersionEventNew event;
    event.release.version.major = static_cast<std::int32_t>((*version)[0]);
    event.release.version.minor = static_cast<std::int32_t>((*version)[1]);
    event.release.version.patch = static_cast<std::int32_t>((*version)[2]);
    event.release.url = state.download_url;
    events.Emit(event);
}

std::vector<Passepartout::Models::ChangelogEntry> VersionChecker::FetchChangelog(const std::string &build) {
    if (!strategy_) throw std::runtime_error("Changelog service is unavailable.");
    return strategy_->FetchChangelog(build);
}

void VersionChecker::Cancel() noexcept {
    if (strategy_) strategy_->Cancel();
}
