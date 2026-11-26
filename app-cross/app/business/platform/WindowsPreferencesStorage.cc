// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "../../context/PreferencesStorage.h"
#include "../../context/PreferencesStorageKey.h"
#include <partout/Json.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.h>

void Passepartout::StoreAppPreferences(
    const Models::AppPreferences &preferences
) {
    winrt::init_apartment(winrt::apartment_type::multi_threaded);
    struct Apartment {
        ~Apartment() {
            winrt::uninit_apartment();
        }
    } apartment;
    // One atomic package setting is read by the host at the next activation.
    winrt::Windows::Storage::ApplicationData::Current().LocalSettings().Values().Insert(
        AppPreferencesStorageKey, winrt::box_value(winrt::to_hstring(preferences.ToJson().Encode())));
}
