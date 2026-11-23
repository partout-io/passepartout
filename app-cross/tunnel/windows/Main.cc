// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "PackageConstants.h"

#include <sstream>
#include <stdexcept>
#include <string>

#include <windows.h>
#include <appmodel.h>
#include <winstring.h>
#include <winrt/Windows.ApplicationModel.Core.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>

namespace {

#if defined(_DEBUG) && defined(PASSEPARTOUT_WAIT_FOR_DEBUGGER)
void WaitForDebugger() {
    constexpr ULONGLONG TimeoutMilliseconds = 30000;
    const auto started = GetTickCount64();
    OutputDebugStringW(L"VPN host waiting up to 30 seconds for a debugger.\n");
    while (!IsDebuggerPresent()) {
        if (GetTickCount64() - started >= TimeoutMilliseconds) {
            OutputDebugStringW(L"VPN host debugger wait timed out; continuing startup.\n");
            return;
        }
        Sleep(100);
    }
    // Stop before loading the plugin so pending breakpoints can be configured.
    DebugBreak();
}
#endif

struct PluginFactories : winrt::implements<PluginFactories, winrt::Windows::Foundation::IGetActivationFactory> {
    PluginFactories() {
        // Keep one loader reference for the process lifetime, even if factory
        // lookup fails. Unloading this dependency chain can leave Go runtime
        // threads executing code from the unloaded WireGuard DLL.
        static const HMODULE module = [] {
            const auto loaded = LoadPackagedLibrary(Passepartout::PackageConstants::PluginFile, 0);
            if (!loaded) winrt::throw_last_error();
            return loaded;
        }();
        factory_ = reinterpret_cast<Factory>(GetProcAddress(module, "DllGetActivationFactory"));
        if (!factory_) {
            winrt::throw_last_error();
        }
    }

    winrt::Windows::Foundation::IInspectable GetActivationFactory(winrt::hstring const &class_id) {
        winrt::Windows::Foundation::IActivationFactory factory{nullptr};
        winrt::check_hresult(
            factory_(static_cast<HSTRING>(winrt::get_abi(class_id)), winrt::put_abi(factory)));
        return factory;
    }

private:
    using Factory = HRESULT(__stdcall *)(HSTRING, void **);
    Factory factory_ = nullptr;
};

} // namespace

using namespace winrt::Windows::Foundation;

static int RunHost() {
    try {
        winrt::init_apartment();
        winrt::Windows::ApplicationModel::Core::CoreApplication::RunWithActivationFactories(
            winrt::make<PluginFactories>());
        return 0;
    } catch (winrt::hresult_error const &error) {
        std::wostringstream message;
        message << L"VPN host failed (0x" << std::hex
                << static_cast<unsigned long>(error.code().value) << L"): "
                << error.message().c_str() << L"\n";
        OutputDebugStringW(message.str().c_str());
    } catch (std::exception const &error) {
        OutputDebugStringA(error.what());
        OutputDebugStringA("\n");
    } catch (...) {
        OutputDebugStringW(L"VPN host failed with an unknown exception.\n");
    }
    return 1;
}

// Package registration belongs to developer tooling; this executable only hosts the plugin.
int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
    UINT32 length = 0;
    const auto result = GetCurrentPackageFullName(&length, nullptr);
    if (result == APPMODEL_ERROR_NO_PACKAGE) {
        OutputDebugStringW(L"Activate the VPN host through its registered package.\n");
        return 1;
    }
    if (result != ERROR_INSUFFICIENT_BUFFER) {
        OutputDebugStringW((std::wstring{L"Unable to determine package identity: "} +
                            std::to_wstring(result) + L"\n")
                               .c_str());
        return 1;
    }
#if defined(_DEBUG) && defined(PASSEPARTOUT_WAIT_FOR_DEBUGGER)
    WaitForDebugger();
#endif
    return RunHost();
}
