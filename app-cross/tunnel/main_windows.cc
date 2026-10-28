// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include <filesystem>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

#include <windows.h>
#include <appmodel.h>
#include <winstring.h>
#include <winrt/Windows.ApplicationModel.Core.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Management.Deployment.h>

// FIXME: ###, Replace development registration with signed production packaging and updates.
static int RegisterPackage() {
    try {
        winrt::init_apartment();

        std::wstring executable(32768, L'\0');
        const auto length =
            GetModuleFileNameW(nullptr, executable.data(), static_cast<DWORD>(executable.size()));
        if (!length) {
            winrt::throw_last_error();
        }
        if (length == executable.size()) {
            throw std::runtime_error("Executable path is too long");
        }
        executable.resize(length);
        const auto manifest = std::filesystem::path{executable}.parent_path() / L"AppxManifest.xml";
        if (!std::filesystem::is_regular_file(manifest)) {
            throw std::runtime_error(
                "Plugin manifest is missing; install passepartout-tunnel first");
        }

        using namespace winrt::Windows::Management::Deployment;
        const PackageManager manager;
        auto refresh_registration = [&](bool changed_manifest) {
            std::vector<winrt::hstring> packages;
            for (const auto &package : manager.FindPackagesForUser(L"", L"Passepartout.VpnChannel",
                                                                   L"CN=Passepartout VpnChannel")) {
                const auto installed =
                    std::filesystem::path{package.InstalledLocation().Path().c_str()};
                std::error_code error;
                if (!package.IsDevelopmentMode()) {
                    throw std::runtime_error("A non-development VPN package is already installed");
                }
                if (!changed_manifest &&
                    std::filesystem::equivalent(installed, manifest.parent_path(), error)) {
                    continue;
                }
                packages.push_back(package.Id().FullName());
            }
            for (const auto &package : packages) {
                OutputDebugStringW((std::wstring{L"Refreshing development registration for "} +
                                    package.c_str() + L"\n")
                                       .c_str());
                const auto removal =
                    manager.RemovePackageAsync(package, RemovalOptions::PreserveApplicationData)
                        .get();
                if (removal.ExtendedErrorCode().value < 0) {
                    throw winrt::hresult_error{removal.ExtendedErrorCode(), removal.ErrorText()};
                }
            }
        };
        auto register_package = [&] {
            const auto operation =
                manager.RegisterPackageAsync(winrt::Windows::Foundation::Uri{manifest.wstring()},
                                             nullptr, DeploymentOptions::DevelopmentMode);
            // Deployment can complete normally while reporting a failed result.
            const auto result = operation.get();
            if (result.ExtendedErrorCode().value < 0) {
                throw winrt::hresult_error{result.ExtendedErrorCode(), result.ErrorText()};
            }
        };
        // A new path can silently retain the old installation; a changed manifest
        // at the same version instead returns ERROR_PACKAGE_ALREADY_EXISTS.
        refresh_registration(false);
        try {
            register_package();
        } catch (winrt::hresult_error const &error) {
            if (error.code() != HRESULT_FROM_WIN32(ERROR_PACKAGE_ALREADY_EXISTS)) {
                throw;
            }
            refresh_registration(true);
            register_package();
        }
        OutputDebugStringW((std::wstring{L"VPN plugin registered from "} + manifest.wstring() +
                            L"\nWindows can now activate Passepartout.VpnChannel.BackgroundTask.\n")
                               .c_str());
        return 0;
    } catch (winrt::hresult_error const &error) {
        // FIXME: ###, Surface registration failures to users when no debugger is attached.
        std::wostringstream message;
        message
            << L"Plugin registration failed (0x" << std::hex
            << static_cast<unsigned long>(error.code().value) << L"): " << error.message().c_str()
            << L"\nLoose packages require Windows Developer Mode and Microsoft.VCLibs.140.00.\n";
        OutputDebugStringW(message.str().c_str());
    } catch (std::exception const &error) {
        OutputDebugStringA(error.what());
        OutputDebugStringA("\n");
    } catch (...) {
        OutputDebugStringW(L"Plugin registration failed with an unknown exception.\n");
    }
    return 1;
}

using namespace winrt::Windows::Foundation;

namespace {

struct PluginFactories : winrt::implements<PluginFactories, IGetActivationFactory> {
    PluginFactories() {
        module_ = LoadPackagedLibrary(L"passepartout-vpnchannel.dll", 0);
        if (!module_) {
            winrt::throw_last_error();
        }
        factory_ = reinterpret_cast<Factory>(GetProcAddress(module_, "DllGetActivationFactory"));
        if (!factory_) {
            const auto error = GetLastError();
            FreeLibrary(module_);
            winrt::throw_hresult(HRESULT_FROM_WIN32(error));
        }
    }

    ~PluginFactories() {
        FreeLibrary(module_);
    }

    IInspectable GetActivationFactory(winrt::hstring const &class_id) {
        IActivationFactory factory{nullptr};
        winrt::check_hresult(
            factory_(static_cast<HSTRING>(winrt::get_abi(class_id)), winrt::put_abi(factory)));
        return factory;
    }

private:
    using Factory = HRESULT(__stdcall *)(HSTRING, void **);
    HMODULE module_ = nullptr;
    Factory factory_ = nullptr;
};

} // namespace

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

// Direct launches register the package; packaged activation hosts the VPN plugin.
int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
    UINT32 length = 0;
    const auto result = GetCurrentPackageFullName(&length, nullptr);
    if (result == APPMODEL_ERROR_NO_PACKAGE) {
        return RegisterPackage();
    }
    if (result != ERROR_INSUFFICIENT_BUFFER) {
        OutputDebugStringW((std::wstring{L"Unable to determine package identity: "} +
                            std::to_wstring(result) + L"\n")
                               .c_str());
        return 1;
    }
    return RunHost();
}
