// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "WindowsPreferencesRepository.h"
#include "../extensions/Models+Business.h"
#include <roapi.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.h>

namespace {
class Apartment final {
public:
    Apartment();
    ~Apartment();
private:
    bool initialized_;
};

Apartment::Apartment() {
    const auto result = RoInitialize(RO_INIT_MULTITHREADED);
    // LocalSettings works in either apartment; preserve an existing UI STA.
    if (result != RPC_E_CHANGED_MODE) winrt::check_hresult(result);
    initialized_ = SUCCEEDED(result);
}

Apartment::~Apartment() {
    if (initialized_) RoUninitialize();
}
}

using Passepartout::Windows::PreferencesRepository;

PreferencesRepository::PreferencesRepository(std::wstring key) : key_(std::move(key)) {}

Passepartout::Models::AppPreferences PreferencesRepository::Fetch() {
    const Apartment apartment;
    const auto values = winrt::Windows::Storage::ApplicationData::Current().LocalSettings().Values();
    const auto defaults = Preferences::Defaults();
    auto preferences = defaults;
    if (values.HasKey(key_)) {
        const auto encoded = winrt::unbox_value<winrt::hstring>(values.Lookup(key_));
        const auto data = Partout::Json::Parse(winrt::to_string(encoded));
        if (!data.IsObject()) throw std::runtime_error("Invalid preferences.");
        auto merged = defaults.ToJson();
        merged.Merge(data);
        preferences = Models::AppPreferences::FromJson(merged);
        preferences.cryptoBackend = defaults.cryptoBackend;
    }
    return preferences;
}

void PreferencesRepository::Save(const Models::AppPreferences &preferences) {
    const Apartment apartment;
    winrt::Windows::Storage::ApplicationData::Current().LocalSettings().Values().Insert(
        key_, winrt::box_value(winrt::to_hstring(preferences.ToJson().Encode()))
    );
}
