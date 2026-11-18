// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "WindowsTunnel.h"
#include "partout_windows.h"
#include "../business/AppLogger.h"
#include "../../tunnel/Preferences.h"
#include <partout/models/TunnelSnapshot.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.h>
#include <stdexcept>

namespace Passepartout {
namespace {
class WindowsTunnelStrategy final : public TunnelStrategy {
public:
    WindowsTunnelStrategy(const std::string &serverUri, std::vector<std::string> dnsFallbackServers)
        : tunnel_(serverUri), dnsFallbackServers_(std::move(dnsFallbackServers)) {}
    std::vector<Models::AppTunnelInfo> Fetch() override {
        std::vector<Models::AppTunnelInfo> result;
        for (const auto &snapshot : tunnel_.Fetch(&observationErrors_)) {
            Models::AppTunnelInfo info{};
            info.id = snapshot.id;
            info.isEnabled = snapshot.isEnabled;
            info.onDemand = snapshot.onDemand;
            if (snapshot.environment) {
                Models::ProfileTransfer transfer{};
                transfer.received = snapshot.environment->dataCount.received;
                transfer.sent = snapshot.environment->dataCount.sent;
                info.transfer = transfer;
                info.lastErrorCode = snapshot.environment->lastErrorCode;
            }
            switch (snapshot.status.value) {
                case Partout::Models::TunnelStatus::inactive: info.status.value = Status::disconnected; break;
                case Partout::Models::TunnelStatus::activating: info.status.value = Status::connecting; break;
                case Partout::Models::TunnelStatus::active: info.status.value = Status::connected; break;
                case Partout::Models::TunnelStatus::deactivating: info.status.value = Status::disconnecting; break;
                default: throw std::runtime_error("Unknown tunnel status.");
            }
            result.push_back(std::move(info));
        }
        return result;
    }
    void Save(const Profile &profile) override {
        ValidateProfileIdentity(profile);
        tunnel_.Save(profile);
    }
    std::map<std::string, std::string> ObservationErrors() const override {
        return observationErrors_;
    }
    void Connect(const std::string &id) override {
        tunnel_.Connect(id);
    }
    void ConnectWithCredentials(const std::string &id, const Partout::Models::OpenVpnCredentials &credentials) override {
        tunnel_.Connect(id, credentials.username, credentials.password);
    }
    void Disconnect(const std::string &id) override {
        tunnel_.Disconnect(id);
    }
    void Remove(const std::string &id) override {
        tunnel_.Remove(id);
    }
    void Cancel() noexcept override {
        tunnel_.Cancel();
    }
    void ApplyPreferences(const Models::AppPreferences &preferences) override {
        winrt::init_apartment(winrt::apartment_type::multi_threaded);
        struct Apartment {
            ~Apartment() {
                winrt::uninit_apartment();
            }
        } apartment;
        const nlohmann::json value = {
            {"dnsFallbackServers", preferences.dnsFallsBack ? dnsFallbackServers_ : std::vector<std::string>{}},
            {"logsPrivateData", preferences.logsPrivateData}
        };
        // One atomic package setting is read by the host at the next activation.
        winrt::Windows::Storage::ApplicationData::Current().LocalSettings().Values().Insert(
            tunnelPreferencesKey, winrt::box_value(winrt::to_hstring(value.dump())));
        partout_init_args init{};
        init.log_level = PartoutLogLevelDebug;
        init.logs_private_data = preferences.logsPrivateData;
        init.logger_fn = AppLogger::PartoutMessage;
        if (preferences.logsPrivateData) AppLogger::SetPrivateData(true);
        partout_init(&init);
        if (!preferences.logsPrivateData) AppLogger::SetPrivateData(false);
    }
private:
    Partout::Tunnel tunnel_;
    std::vector<std::string> dnsFallbackServers_;
    std::map<std::string, std::string> observationErrors_;
};
}
std::unique_ptr<TunnelStrategy> MakeWindowsTunnelStrategy(const std::string &serverUri,
                                                        std::vector<std::string> dnsFallbackServers) {
    return std::make_unique<WindowsTunnelStrategy>(serverUri, std::move(dnsFallbackServers));
}
}
