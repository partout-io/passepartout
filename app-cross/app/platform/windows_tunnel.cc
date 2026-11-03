// SPDX-License-Identifier: GPL-3.0
#include "../business/tunnel.h"
#include <winrt/Windows.ApplicationModel.h>
#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Networking.Vpn.h>
#include <chrono>
#include <stdexcept>

namespace Passepartout {
namespace {
using namespace winrt::Windows::Networking::Vpn;
using namespace winrt::Windows::Foundation;
constexpr std::wstring_view Prefix = L"Passepartout ";
struct Apartment {
    Apartment() {
        winrt::init_apartment(winrt::apartment_type::multi_threaded);
    }
    ~Apartment() {
        winrt::uninit_apartment();
    }
};

template<typename Operation>
auto Await(const Operation &operation) {
    if (operation.wait_for(std::chrono::seconds(60)) == AsyncStatus::Started) {
        operation.Cancel();
        throw std::runtime_error("Windows did not finish the VPN request. Refresh its status before retrying.");
    }
    return operation.get();
}
void Check(VpnManagementErrorStatus status) {
    if (status != VpnManagementErrorStatus::Ok)
        throw std::runtime_error("Windows rejected the VPN request (status " +
                                 std::to_string(static_cast<int>(status)) + ").");
}
winrt::hstring Family() {
    try {
        return winrt::Windows::ApplicationModel::Package::Current().Id().FamilyName();
    } catch (...) {
        throw std::runtime_error("Install and launch the packaged Passepartout application to control the VPN.");
    }
}
std::wstring Name(const std::string &id) {
    return std::wstring(Prefix) + winrt::to_hstring(id).c_str();
}
std::vector<VpnPlugInProfile> OwnedProfiles(const VpnManagementAgent &agent) {
    const auto family = Family();
    std::vector<VpnPlugInProfile> result;
    for (const auto &item : Await(agent.GetProfilesAsync())) {
        const auto profile = item.try_as<VpnPlugInProfile>();
        if (!profile || profile.VpnPluginPackageFamilyName() != family) continue;
        const auto name = profile.ProfileName();
        if (std::wstring_view(name).substr(0, Prefix.size()) == Prefix) result.push_back(profile);
    }
    return result;
}
VpnPlugInProfile Find(const VpnManagementAgent &agent, const std::string &id) {
    for (const auto &profile : OwnedProfiles(agent)) {
        if (profile.ProfileName() == Name(id)) return profile;
    }
    return nullptr;
}
template<typename Action>
auto WithAgent(Action action) {
    try {
        Apartment apartment;
        return action(VpnManagementAgent{});
    } catch (const winrt::hresult_error &error) {
        // WinRT messages can echo custom configuration. Report only the code.
        throw std::runtime_error("Windows VPN operation failed (HRESULT " +
                                 std::to_string(error.code().value) + ").");
    }
}

class WindowsTunnelStrategy final : public TunnelStrategy {
public:
    std::vector<Models::AppTunnelInfo> Fetch() override {
        return WithAgent([](const auto &agent) {
            std::vector<Models::AppTunnelInfo> result;
            for (const auto &profile : OwnedProfiles(agent)) {
                Models::AppTunnelInfo info{};
                info.id = winrt::to_string(std::wstring_view(profile.ProfileName()).substr(Prefix.size()));
                switch (profile.ConnectionStatus()) {
                    case VpnManagementConnectionStatus::Disconnected: info.status.value = Status::disconnected; break;
                    case VpnManagementConnectionStatus::Connecting: info.status.value = Status::connecting; break;
                    case VpnManagementConnectionStatus::Connected: info.status.value = Status::connected; break;
                    case VpnManagementConnectionStatus::Disconnecting: info.status.value = Status::disconnecting; break;
                    default: throw std::runtime_error("Windows returned an unknown VPN status.");
                }
                info.isEnabled = info.status.value != Status::disconnected;
                // Management APIs do not expose Partout transfer counters/errors.
                // Leave them absent instead of reporting fabricated zero values.
                result.push_back(std::move(info));
            }
            return result;
        });
    }
    void Save(const Profile &profile) override {
        ValidateProfileIdentity(profile);
        WithAgent([&](const auto &agent) {
            auto existing = Find(agent, profile.id);
            if (existing && existing.ConnectionStatus() != VpnManagementConnectionStatus::Disconnected)
                throw std::runtime_error("Disconnect the VPN before updating its configuration.");
            using namespace winrt::Windows::Data::Xml::Dom;
            const XmlDocument document;
            auto root = document.CreateElement(L"PartoutProfile");
            root.SetAttribute(L"version", L"1");
            root.InnerText(winrt::to_hstring(profile.ToJson().dump()));
            document.AppendChild(root);
            const auto xml = document.GetXml();
            if (xml.size() > 1024 * 1024)
                throw std::runtime_error("The encoded VPN configuration exceeds 1 MiB.");
            auto target = existing ? existing : VpnPlugInProfile{};
            target.ProfileName(Name(profile.id));
            target.VpnPluginPackageFamilyName(Family());
            target.ServerUris().Clear();
            // Required by Windows; Partout obtains actual endpoints from the profile.
            target.ServerUris().Append(Uri(L"https://profile.invalid"));
            target.CustomConfiguration(xml);
            target.RememberCredentials(false);
            Check(existing ? Await(agent.UpdateProfileFromObjectAsync(target))
                           : Await(agent.AddProfileFromObjectAsync(target)));
        });
    }
    void Connect(const std::string &id) override {
        WithAgent([&](const auto &agent) {
            const auto profile = Find(agent, id);
            if (!profile) throw std::runtime_error("The Windows VPN profile is missing.");
            Check(Await(agent.ConnectProfileAsync(profile)));
        });
    }
    void Disconnect(const std::string &id) override {
        WithAgent([&](const auto &agent) {
            const auto profile = Find(agent, id);
            if (!profile || profile.ConnectionStatus() == VpnManagementConnectionStatus::Disconnected) return;
            Check(Await(agent.DisconnectProfileAsync(profile)));
        });
    }
    void Remove(const std::string &id) override {
        WithAgent([&](const auto &agent) {
            const auto profile = Find(agent, id);
            if (!profile) return;
            if (profile.ConnectionStatus() != VpnManagementConnectionStatus::Disconnected)
                throw std::runtime_error("The Windows VPN profile is still active.");
            Check(Await(agent.DeleteProfileAsync(profile)));
        });
    }
};
}
std::unique_ptr<TunnelStrategy> MakeWindowsTunnelStrategy() {
    return std::make_unique<WindowsTunnelStrategy>();
}
}
