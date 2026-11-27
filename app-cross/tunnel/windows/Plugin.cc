// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "PackageConstants.h"
#include "TunnelDefaults.h"
#include "AppPreferences.h"
#include <partout/Json.h>
#include "../../app/context/CrossConstants.h"

#include <atomic>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>

#include <windows.h>
#include <winstring.h>

#include <winrt/Windows.ApplicationModel.Background.h>
#include <winrt/Windows.Data.Json.h>
#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Networking.Vpn.h>
#include <winrt/Windows.Storage.h>
#include <winrt/base.h>

#include <partout/winrt/VpnChannelRuntime.h>

namespace {

constexpr std::wstring_view BackgroundTaskClass = Passepartout::PackageConstants::BackgroundTask;
std::atomic_uint64_t g_log_sequence = 0;
std::atomic_bool logs_private_data{false};

void Log(std::wstring_view message, winrt::Windows::Networking::Vpn::VpnChannel const &channel = nullptr) noexcept {
    std::wstring line;
    try {
        const auto sequence = ++g_log_sequence;
        line = std::to_wstring(sequence);
        line += L" [PID " + std::to_wstring(GetCurrentProcessId());
        line += L" TID " + std::to_wstring(GetCurrentThreadId()) + L"] ";
        line += message;
        line += L"\n";
    } catch (...) {
        return;
    }

    try {
        if (channel) {
            channel.LogDiagnosticMessage(winrt::hstring{line});
        }
    } catch (...) {
        // Debugger logging remains available if system diagnostics are unavailable.
    }

    try {
        OutputDebugStringW(line.c_str());
    } catch (...) {
        // Diagnostics must never make a VPN lifecycle callback fail.
    }
}

void LogPartoutModulePath() noexcept {
    try {
        // Inspect the loaded module without loading another copy or changing
        // its reference count.
        const auto module = GetModuleHandleW(L"partout.dll");
        if (!module) {
            const auto error = GetLastError();
            Log(L"Loaded partout.dll path unavailable: GetModuleHandleW error " +
                std::to_wstring(error));
            return;
        }
        std::wstring path(32768, L'\0');
        const auto length =
            GetModuleFileNameW(module, path.data(), static_cast<DWORD>(path.size()));
        if (length == 0 || length >= path.size()) {
            const auto error = length == 0 ? GetLastError() : ERROR_INSUFFICIENT_BUFFER;
            Log(L"Loaded partout.dll path unavailable: GetModuleFileNameW error " +
                std::to_wstring(error));
            return;
        }
        path.resize(length);
        Log(L"Loaded partout.dll: " + path);
    } catch (...) {
        Log(L"Loaded partout.dll path unavailable: unexpected exception");
    }
}

// CustomField is the per-connection CustomConfiguration XML supplied by Windows.
// Never fall back to a bundled profile or a process-wide test configuration.
std::string ReadProfile(winrt::Windows::Networking::Vpn::VpnChannel const &channel) {
    std::wstring_view stage = L"reading Windows custom configuration";
    try {
        const auto configuration = channel.Configuration().CustomField();
        if (configuration.empty() || configuration.size() > 1024 * 1024) {
            throw winrt::hresult_invalid_argument();
        }
        using namespace winrt::Windows::Data::Xml::Dom;
        const XmlLoadSettings settings;
        settings.ProhibitDtd(true);
        settings.ResolveExternals(false);
        settings.MaxElementDepth(8);
        const XmlDocument document;
        stage = L"parsing custom configuration XML";
        document.LoadXml(configuration, settings);
        stage = L"validating PartoutProfile XML";
        const auto root = document.DocumentElement();
        if (!root || root.TagName() != L"PartoutProfile" ||
            root.GetAttribute(L"version") != L"1") {
            throw winrt::hresult_invalid_argument();
        }
        std::wstring json;
        bool has_connection_details = false;
        for (const auto &node : root.ChildNodes()) {
            if (node.NodeType() == NodeType::TextNode ||
                node.NodeType() == NodeType::DataSectionNode) {
                json += node.InnerText();
            } else if (node.NodeType() == NodeType::ElementNode &&
                       node.NodeName() == L"ConnectionDetails" && !has_connection_details) {
                // Windows inserts connection metadata before our profile text.
                // Its inner text must never become part of the JSON payload.
                has_connection_details = true;
            } else {
                throw winrt::hresult_invalid_argument();
            }
        }
        if (json.empty() || std::wstring_view{json}.find(L'\0') != std::wstring_view::npos) {
            throw winrt::hresult_invalid_argument();
        }
        // Check syntax here; Partout validates the profile schema when connecting.
        stage = L"parsing profile JSON";
        winrt::Windows::Data::Json::JsonObject::Parse(winrt::hstring{json});
        return winrt::to_string(json);
    } catch (...) {
        Log(L"Profile rejected while " + std::wstring{stage} + L"; HRESULT=" +
            std::to_wstring(winrt::to_hresult().value), channel);
        // Parser exceptions can include profile contents. Expose only a fixed message.
        throw winrt::hresult_invalid_argument(L"Missing or invalid PartoutProfile configuration.");
    }
}

void LogNative(void *, const char *profile_id, int, const char *message) noexcept {
    try {
        if (!message) return;
        const auto text = profile_id && logs_private_data.load() ?
            "[" + std::string(profile_id) + "] " + message : std::string(message);
        Log(winrt::to_hstring(text));
    } catch (...) {
        // Never throw through the native logging callback.
    }
}

// The native daemon is process-wide. The lease survives every borrowed callback
// and is released only after runtime teardown, including failed/canceled startup.
std::atomic_bool channel_owned{false};
struct ChannelLease {
    ChannelLease() {
        if (channel_owned.exchange(true)) throw winrt::hresult_illegal_method_call(L"A VPN channel is already active.");
    }

    ~ChannelLease() {
        channel_owned.store(false);
    }
};
struct ChannelSession {
    ChannelLease lease;
    winrt::Windows::Networking::Vpn::VpnChannel channel;
    // Guarded by VpnPlugin's ownership mutex. Startup owns teardown until it
    // explicitly hands the session over to Disconnect.
    bool starting = true;
    std::atomic_bool canceled{false};
    std::unique_ptr<Partout::VpnChannelRuntime> runtime;

    explicit ChannelSession(winrt::Windows::Networking::Vpn::VpnChannel const &value) : channel(value) {
        const auto profile = ReadProfile(channel);
        const auto values = winrt::Windows::Storage::ApplicationData::Current().LocalSettings().Values();
        // Before the first app preference write, use the tunnel's default behavior.
        Passepartout::Models::AppPreferences preferences{};
        preferences.dnsFallsBack = true;
        const auto &preferences_key = Passepartout::CrossConstants.storage.preferences_key;
        if (values.HasKey(preferences_key)) {
            const auto encoded_preferences = winrt::unbox_value<winrt::hstring>(values.Lookup(preferences_key));
            preferences = Passepartout::Models::AppPreferences::FromJson(
                Partout::Json::Parse(winrt::to_string(encoded_preferences))
            );
        }
        Partout::Runtime::InitializationOptions init{};
        init.logger_fn = LogNative;
        init.log_level = Partout::Runtime::LogLevel::Debug;
        init.logs_private_data = preferences.logsPrivateData;
        logs_private_data.store(init.logs_private_data);
        const auto temporary = winrt::to_string(winrt::Windows::Storage::ApplicationData::Current().TemporaryFolder().Path());
        Partout::Runtime::DaemonOptions options{};
        options.cache_dir = temporary;
        options.starts_immediately = true;
        options.crypto = Partout::Runtime::CryptoBackend::MbedTLS;
        Partout::Models::TunnelControllerOptions controller_options{};
        if (preferences.dnsFallsBack) {
            for (const auto &server : Partout::Json::Parse(Passepartout::DNSFallbackServers).Elements()) {
                controller_options.dnsFallbackServers.push_back(server.Get<std::string>());
            }
        }
        runtime = std::make_unique<Partout::VpnChannelRuntime>(
            channel, profile, init, options, std::move(controller_options));
    }

    void Cancel() noexcept {
        canceled.store(true);
        // FIXME: ### Restore VpnChannelRuntime::Cancel after 39140181 is merged.
        // Partout master cannot interrupt startup; Connect observes this flag
        // on completion and performs teardown on its owning thread.
    }
};

struct PluginState {
    std::mutex mutex;
    std::shared_ptr<ChannelSession> session;
};

struct VpnPlugin : winrt::implements<VpnPlugin, winrt::Windows::Networking::Vpn::IVpnPlugIn> {
    explicit VpnPlugin(std::shared_ptr<PluginState> state) : state_(std::move(state)) {}

    void Connect(winrt::Windows::Networking::Vpn::VpnChannel const &channel) {
        Log(L"VPN connect requested", channel);
        std::shared_ptr<ChannelSession> session;
        {
            std::scoped_lock lock(state_->mutex);
            if (canceled_) throw winrt::hresult_canceled();
            if (state_->session) throw winrt::hresult_illegal_method_call(L"A VPN channel is already active.");
            session = std::make_shared<ChannelSession>(channel);
            state_->session = session;
            startup_ = session;
        }
        // No ownership mutex is held through startup or native callbacks.
        try {
            session->runtime->Connect(channel);
            bool stop = false;
            {
                std::scoped_lock lock(state_->mutex);
                session->starting = false;
                stop = session->canceled.load();
                if (stop && state_->session == session) state_->session.reset();
            }
            if (stop) session->runtime->Disconnect(channel);
        } catch (...) {
            std::scoped_lock lock(state_->mutex);
            if (state_->session == session) state_->session.reset();
            throw;
        }
    }

    void Disconnect(winrt::Windows::Networking::Vpn::VpnChannel const &channel) {
        std::shared_ptr<ChannelSession> session;
        bool stop = false;
        {
            std::scoped_lock lock(state_->mutex);
            if (!state_->session || state_->session->channel != channel) return;
            session = std::move(state_->session);
            session->Cancel();
            stop = !session->starting;
        }
        // Startup owns teardown while connecting. Never wait on a reentrant
        // callback from Connect/Stop; the last borrowed session releases it.
        if (stop) session->runtime->Disconnect(channel);
    }

    void CancelStartup() noexcept {
        try {
            std::scoped_lock lock(state_->mutex);
            canceled_ = true;
            const auto session = startup_.lock();
            if (session && session->starting) session->Cancel();
        } catch (...) {}
    }

    void GetKeepAlivePayload(winrt::Windows::Networking::Vpn::VpnChannel const &channel, winrt::Windows::Networking::Vpn::VpnPacketBuffer &packet) {
        const auto session = Borrow(channel);
        if (!session) {
            packet = nullptr;
            return;
        }
        session->runtime->GetKeepAlivePayload(channel, packet);
    }

    void Encapsulate(winrt::Windows::Networking::Vpn::VpnChannel const &channel, winrt::Windows::Networking::Vpn::VpnPacketBufferList const &packets,
                     winrt::Windows::Networking::Vpn::VpnPacketBufferList const &encapsulated) {
        const auto session = Borrow(channel);
        if (session) session->runtime->Encapsulate(channel, packets, encapsulated);
    }

    void Decapsulate(winrt::Windows::Networking::Vpn::VpnChannel const &channel, winrt::Windows::Networking::Vpn::VpnPacketBuffer const &packet,
                     winrt::Windows::Networking::Vpn::VpnPacketBufferList const &decapsulated, winrt::Windows::Networking::Vpn::VpnPacketBufferList const &control) {
        const auto session = Borrow(channel);
        if (session) session->runtime->Decapsulate(channel, packet, decapsulated, control);
    }

private:
    std::shared_ptr<ChannelSession> Borrow(winrt::Windows::Networking::Vpn::VpnChannel const &channel) {
        std::scoped_lock lock(state_->mutex);
        const auto &session = state_->session;
        return session && session->channel == channel && !session->canceled.load() ? session : nullptr;
    }
    std::shared_ptr<PluginState> state_;
    // One plugin adapter per background event. Cancellation can only affect
    // startup initiated by that event, never a later connection.
    std::weak_ptr<ChannelSession> startup_;
    bool canceled_ = false;
};

struct VpnBackgroundTask : winrt::implements<VpnBackgroundTask, winrt::Windows::ApplicationModel::Background::IBackgroundTask> {
    void Run(winrt::Windows::ApplicationModel::Background::IBackgroundTaskInstance const &task) {
        const auto deferral = task.GetDeferral();
        try {
            static std::once_flag module_path_logged;
            std::call_once(module_path_logged, LogPartoutModulePath);
            static const auto state = std::make_shared<PluginState>();
            const auto plugin = winrt::make_self<VpnPlugin>(state);
            const auto cancellation = task.Canceled(winrt::auto_revoke, [plugin](auto const &, auto) {
                plugin->CancelStartup();
            });
            winrt::Windows::Networking::Vpn::VpnChannel::ProcessEventAsync(plugin.as<winrt::Windows::Networking::Vpn::IVpnPlugIn>(), task.TriggerDetails());
        } catch (winrt::hresult_error const &error) {
            Log(L"Background task failed: HRESULT=" + std::to_wstring(error.code().value));
            deferral.Complete();
            throw;
        } catch (...) {
            Log(L"Background task failed with an unknown exception");
            deferral.Complete();
            throw;
        }
        deferral.Complete();
    }
};

struct VpnBackgroundTaskFactory : winrt::implements<VpnBackgroundTaskFactory, winrt::Windows::Foundation::IActivationFactory> {
    winrt::Windows::Foundation::IInspectable ActivateInstance() {
        return winrt::make<VpnBackgroundTask>();
    }
};

} // namespace

using namespace winrt;
using namespace winrt::Windows::ApplicationModel::Background;
using namespace winrt::Windows::Foundation;
using namespace winrt::Windows::Networking::Vpn;
using namespace winrt::Windows::Storage;

extern "C" HRESULT __stdcall DllGetActivationFactory(HSTRING class_id, void **factory) noexcept {
    if (!factory) return E_POINTER;
    *factory = nullptr;
    if (!class_id) return E_INVALIDARG;

    uint32_t length = 0;
    const wchar_t *raw = WindowsGetStringRawBuffer(class_id, &length);
    if (std::wstring_view{raw, length} != BackgroundTaskClass) {
        return CLASS_E_CLASSNOTAVAILABLE;
    }

    try {
        auto value = winrt::make<VpnBackgroundTaskFactory>();
        *factory = winrt::detach_abi(value);
        return S_OK;
    } catch (...) {
        return winrt::to_hresult();
    }
}

extern "C" HRESULT __stdcall DllCanUnloadNow() {
    return S_FALSE;
}
