// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

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

#include "partout.h"
#include "partout_winrt.h"

using namespace winrt;
using namespace winrt::Windows::ApplicationModel::Background;
using namespace winrt::Windows::Foundation;
using namespace winrt::Windows::Networking::Vpn;
using namespace winrt::Windows::Storage;

namespace {

constexpr std::wstring_view kBackgroundTaskClass = L"Passepartout.VpnChannel.BackgroundTask";
constexpr std::wstring_view kLogName = L"vpnchannel.log";

std::mutex g_log_mutex;
std::atomic_uint64_t g_log_sequence = 0;
// FIXME: ###, Bound log size and retention, and filter verbose native logs for production.
winrt::handle g_log_file;

// Resolve package storage on the background-task thread, before native workers
// start logging. Worker callbacks must not activate WinRT storage or await I/O.
void InitializeLog() noexcept {
    try {
        std::scoped_lock lock(g_log_mutex);
        if (g_log_file) return;
        const auto folder = ApplicationData::Current().LocalFolder();
        const auto path = std::wstring{folder.Path()} + L"\\" + std::wstring{kLogName};
        const auto file = CreateFile2(path.c_str(), FILE_APPEND_DATA,
                                     FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                                     OPEN_ALWAYS, nullptr);
        if (file != INVALID_HANDLE_VALUE) g_log_file.attach(file);
    } catch (...) {
        OutputDebugStringW(L"Unable to open VPN log; debugger logging remains available.\n");
    }
}

void Log(std::wstring_view message, VpnChannel const &channel = nullptr) noexcept {
    std::wstring line;
    try {
        const auto sequence = ++g_log_sequence;
        line = std::to_wstring(sequence);
        line += L" [PID " + std::to_wstring(GetCurrentProcessId());
        line += L" TID " + std::to_wstring(GetCurrentThreadId()) + L"] ";
        line += message;
        line += L"\r\n";
    } catch (...) {
        return;
    }

    try {
        if (channel) {
            channel.LogDiagnosticMessage(winrt::hstring{line});
        }
    } catch (...) {
        // The LocalState log below remains useful if system diagnostics are unavailable.
    }

    try {
        OutputDebugStringW(line.c_str());

        std::scoped_lock lock(g_log_mutex);
        if (!g_log_file) return;
        const auto utf8 = winrt::to_string(line);
        if (utf8.size() > MAXDWORD) return;
        DWORD written = 0;
        WriteFile(g_log_file.get(), utf8.data(), static_cast<DWORD>(utf8.size()), &written,
                  nullptr);
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
std::string ReadProfile(VpnChannel const &channel) {
    std::wstring_view stage = L"reading Windows custom configuration";
    try {
        const auto configuration = channel.Configuration().CustomField();
        if (configuration.empty() || configuration.size() > 1024 * 1024) {
            throw hresult_invalid_argument();
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
            throw hresult_invalid_argument();
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
                throw hresult_invalid_argument();
            }
        }
        if (json.empty() || std::wstring_view{json}.find(L'\0') != std::wstring_view::npos) {
            throw hresult_invalid_argument();
        }
        // Check syntax here; Partout validates the profile schema when connecting.
        stage = L"parsing profile JSON";
        winrt::Windows::Data::Json::JsonObject::Parse(winrt::hstring{json});
        return winrt::to_string(json);
    } catch (...) {
        Log(L"Profile rejected while " + std::wstring{stage} + L"; HRESULT=" +
            std::to_wstring(winrt::to_hresult().value), channel);
        // Parser exceptions can include profile contents. Expose only a fixed message.
        throw hresult_invalid_argument(L"Missing or invalid PartoutProfile configuration.");
    }
}

void LogNative(void *, int, const char *message) noexcept {
    try {
        if (message) Log(winrt::to_hstring(message));
    } catch (...) {
        // Never throw through the native logging callback.
    }
}

struct VpnPlugin : winrt::implements<VpnPlugin, IVpnPlugIn> {
    void Connect(VpnChannel const &channel) {
        Log(L"VPN connect requested", channel);
        // FIXME: ###, Scope runtimes by channel or reject a second channel before resetting
        // the active connection; the native daemon is currently process-wide.
        std::scoped_lock lock(runtime_mutex_);
        runtime_.reset();
        const auto profile = ReadProfile(channel);

        // FIXME: ###, Apply user preferences here.
        partout_init_args init_args{};
        init_args.logger_fn = LogNative;
        init_args.logs_private_data = false;
        const auto temp_dir = winrt::to_string(ApplicationData::Current().TemporaryFolder().Path());
        partout_daemon_options options{};
        options.cache_dir = temp_dir.c_str();
        options.starts_immediately = true;
        options.crypto = PartoutCryptoNative;

        auto runtime = std::make_unique<Partout::VpnChannelRuntime>(
            channel, profile.c_str(), init_args, options);
        // FIXME: ###, Allow cancellation during startup and verify callback reentrancy:
        // this mutex stays locked throughout the native connection wait and teardown.
        // FIXME: ###, Complete native kill-switch and cancellation support before release
        // (partout/cross/windows/src/platform.cc).
        runtime->Connect(channel);
        runtime_ = std::move(runtime);
    }

    void Disconnect(VpnChannel const &channel) {
        std::scoped_lock lock(runtime_mutex_);
        if (!runtime_) return;
        runtime_->Disconnect(channel);
        runtime_.reset();
    }

    void GetKeepAlivePayload(VpnChannel const &channel, VpnPacketBuffer &packet) {
        std::scoped_lock lock(runtime_mutex_);
        if (!runtime_) {
            packet = nullptr;
            return;
        }
        runtime_->GetKeepAlivePayload(channel, packet);
    }

    void Encapsulate(VpnChannel const &channel, VpnPacketBufferList const &packets,
                     VpnPacketBufferList const &encapsulated_packets) {
        std::scoped_lock lock(runtime_mutex_);
        if (!runtime_) return;
        runtime_->Encapsulate(channel, packets, encapsulated_packets);
    }

    void Decapsulate(VpnChannel const &channel, VpnPacketBuffer const &packet,
                     VpnPacketBufferList const &decapsulated_packets,
                     VpnPacketBufferList const &control_packets) {
        std::scoped_lock lock(runtime_mutex_);
        if (!runtime_) return;
        runtime_->Decapsulate(channel, packet, decapsulated_packets, control_packets);
    }

private:
    std::mutex runtime_mutex_;
    std::unique_ptr<Partout::VpnChannelRuntime> runtime_;
};

struct VpnBackgroundTask : winrt::implements<VpnBackgroundTask, IBackgroundTask> {
    void Run(IBackgroundTaskInstance const &task) {
        // FIXME: ###, Handle background-task cancellation and verify reconnect after
        // suspension, host termination, and network changes on x64 and ARM64.
        const auto deferral = task.GetDeferral();
        try {
            InitializeLog();
            static std::once_flag module_path_logged;
            std::call_once(module_path_logged, LogPartoutModulePath);
            static const IVpnPlugIn plugin = winrt::make<VpnPlugin>();
            VpnChannel::ProcessEventAsync(plugin, task.TriggerDetails());
        } catch (winrt::hresult_error const &error) {
            Log(L"Background task failed: " + std::wstring{error.message().c_str()});
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

struct VpnBackgroundTaskFactory : winrt::implements<VpnBackgroundTaskFactory, IActivationFactory> {
    IInspectable ActivateInstance() {
        return winrt::make<VpnBackgroundTask>();
    }
};

} // namespace

extern "C" HRESULT __stdcall DllGetActivationFactory(HSTRING class_id, void **factory) noexcept {
    if (!factory) return E_POINTER;
    *factory = nullptr;
    if (!class_id) return E_INVALIDARG;

    uint32_t length = 0;
    const wchar_t *raw = WindowsGetStringRawBuffer(class_id, &length);
    if (std::wstring_view{raw, length} != kBackgroundTaskClass) {
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
