// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "StateObserver.h"

wxDEFINE_EVENT(wxEVT_PASSEPARTOUT_STATE_CHANGED, wxThreadEvent);

namespace Passepartout {
StateObserver::StateObserver(std::function<void()> update) {
    Bind(wxEVT_PASSEPARTOUT_STATE_CHANGED, [update = std::move(update)](wxThreadEvent &) {
        update();
    });
}

StateObserver::~StateObserver() {
    Stop();
}

void StateObserver::Observe(EventEmitter<> &source) {
    const auto subscription = source.Subscribe([this] {
        wxQueueEvent(this, new wxThreadEvent(wxEVT_PASSEPARTOUT_STATE_CHANGED));
    });
    subscriptions_.emplace_back(&source, subscription);
}

void StateObserver::Stop() {
    for (const auto &[source, subscription] : subscriptions_) source->Unsubscribe(subscription);
    subscriptions_.clear();
    // No source can queue another update after all subscriptions have ended.
    DeletePendingEvents();
}
}
