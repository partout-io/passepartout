// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "MainThread.h"
#include "../business/extensions/EventEmitter.h"
#include "../business/extensions/Models+Business.h"

namespace Passepartout {
class ProfileEditor final {
public:
    EventEmitter<> changes;
    struct State final {
        Profile draft;
        bool saving = false;
        bool saved = false;
        bool operation_failed = false;
    };
    explicit ProfileEditor(Profile profile);
    State Snapshot() const;
    const Profile &Original() const;
    void Rename(std::string name);
    void UpdateModule(const Partout::Models::TaggedModule &module);
    bool CanSave() const;
    bool BeginSave();
    void FinishSave(bool succeeded);
    void ClearOperationError();
private:
    MainThread delivery_;
    bool IsValidChange() const;
    const Profile original_;
    State state_;
};
}
