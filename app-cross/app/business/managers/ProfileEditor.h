// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../extensions/ModelsExtensions.h"
#include <mutex>

namespace Passepartout {
class ProfileEditor {
public:
    struct State {
        Profile draft;
        bool saving = false;
        bool saved = false;
        bool failed = false;
    };
    explicit ProfileEditor(Profile profile);
    State Snapshot() const;
    const Profile &Original() const;
    void Rename(std::string name);
    void UpdateModule(const Partout::Models::TaggedModule &module);
    bool CanSave() const;
    bool BeginSave();
    void FinishSave(bool succeeded);
    void ClearError();
private:
    bool IsValidChange() const;
    const Profile original_;
    mutable std::mutex mutex_;
    State state_;
};
}
