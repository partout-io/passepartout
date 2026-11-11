// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "business/profiles.h"
#include <partout/models/ABIEnvelope.h>
#include <stdexcept>

namespace Passepartout {
inline Profile DecodeImportResult(const char *json) {
    if (!json) throw std::runtime_error("Partout could not import this configuration.");
    try {
        const auto envelope = Partout::Models::ABIEnvelope::FromJson(nlohmann::json::parse(json));
        if (envelope.code || !envelope.payload)
            throw std::runtime_error("Import failed");
        return Profile::FromJson(*envelope.payload);
    } catch (...) {
        // ABI errors and parser details may contain configuration secrets.
        throw std::runtime_error("Partout could not import this configuration.");
    }
}
}
