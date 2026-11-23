// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "WindowsTunnelPreferences.h"
#include "../extensions/AppLogger.h"
#include "../../../tunnel/Preferences.h"
#include "partout.h"
#include <partout/Json.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.h>

void Passepartout::Windows::Tunnel::ApplyPreferences(
    const Models::AppPreferences &preferences, const std::vector<std::string> &dnsFallbackServers
) {
    winrt::init_apartment(winrt::apartment_type::multi_threaded);
    struct Apartment {
        ~Apartment() {
            winrt::uninit_apartment();
        }
    } apartment;
    const Partout::Json value = {
        {"dnsFallbackServers", preferences.dnsFallsBack ? dnsFallbackServers : std::vector<std::string>{}},
        {"logsPrivateData", preferences.logsPrivateData}
    };
    // One atomic package setting is read by the host at the next activation.
    winrt::Windows::Storage::ApplicationData::Current().LocalSettings().Values().Insert(
        tunnelPreferencesKey, winrt::box_value(winrt::to_hstring(value.Encode())));
    partout_init_args init{};
    init.log_level = PartoutLogLevelDebug;
    init.logs_private_data = preferences.logsPrivateData;
    init.logger_fn = AppLogger::PartoutMessage;
    if (preferences.logsPrivateData) AppLogger::SetPrivateData(true);
    partout_init(&init);
    if (!preferences.logsPrivateData) AppLogger::SetPrivateData(false);
}
