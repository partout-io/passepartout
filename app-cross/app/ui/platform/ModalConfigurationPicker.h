// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ConfigurationPicker.h"
#include <functional>

namespace Passepartout {
// Modal dialogs dispatch UI events, including Poll and Cancel, while selecting.
class ModalConfigurationPicker final : public ConfigurationPicker {
public:
    explicit ModalConfigurationPicker(std::function<ConfigurationPickerResult()> select)
        : select_(std::move(select)) {}

    void Start() override {
        Cancel();
        const auto generation = generation_;
        auto result = select_();
        if (generation == generation_) result_ = std::move(result);
    }

    std::optional<ConfigurationPickerResult> Poll() override {
        auto result = std::move(result_);
        result_.reset();
        return result;
    }

    void Cancel() override {
        ++generation_;
        result_.reset();
    }
private:
    std::function<ConfigurationPickerResult()> select_;
    std::optional<ConfigurationPickerResult> result_;
    std::size_t generation_ = 0;
};
}
