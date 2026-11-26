// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../business/extensions/EventEmitter.h"
#include <wx/event.h>
#include <vector>
#include <utility>

namespace Passepartout {
// Use on the wx main thread and own as the last member of a view.
// Destruction unsubscribes and discards queued updates before view state dies.
// Observed sources must outlive this observer.
class StateObserver final : public wxEvtHandler {
public:
    explicit StateObserver(std::function<void()> update);
    ~StateObserver() override;
    void Observe(EventEmitter<> &source);
    void Stop();
private:
    std::vector<std::pair<EventEmitter<> *, std::size_t>> subscriptions_;
};
}
