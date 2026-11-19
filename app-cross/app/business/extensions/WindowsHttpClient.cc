// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "WindowsHttpClient.h"
#include <atomic>
#include <thread>
#include <stdexcept>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.Web.Http.h>
#include <winrt/Windows.Web.Http.Filters.h>

namespace Passepartout {
namespace {
class WindowsHttpClient final : public HttpClient {
public:
    explicit WindowsHttpClient(std::chrono::milliseconds timeout) : timeout_(timeout) {}
    std::string Get(const std::string &url) override {
        if (canceled_.load()) throw std::runtime_error("HTTP request canceled.");
        winrt::init_apartment(winrt::apartment_type::multi_threaded);
        struct Apartment {
            ~Apartment() {
                winrt::uninit_apartment();
            }
        } apartment;
        using namespace winrt::Windows;
        const Foundation::Uri uri(winrt::to_hstring(url));
        if (uri.SchemeName() != L"https") throw std::runtime_error("HTTPS is required.");
        Web::Http::Filters::HttpBaseProtocolFilter filter;
        filter.AllowAutoRedirect(false);
        Web::Http::HttpClient client(filter);
        const auto deadline = std::chrono::steady_clock::now() + timeout_;
        const auto response = Await(client.GetAsync(uri, Web::Http::HttpCompletionOption::ResponseHeadersRead), deadline);
        if (!response.IsSuccessStatusCode()) throw std::runtime_error("HTTP request failed.");
        auto stream = Await(response.Content().ReadAsInputStreamAsync(), deadline);
        std::string result;
        for (;;) {
            const auto buffer = Await(stream.ReadAsync(Storage::Streams::Buffer(4096), 4096,
                Storage::Streams::InputStreamOptions::Partial), deadline);
            if (!buffer.Length()) break;
            if (result.size() + buffer.Length() > 1024 * 1024) throw std::runtime_error("HTTP response is too large.");
            result.append(reinterpret_cast<const char *>(buffer.data()), buffer.Length());
        }
        return result;
    }
    void Cancel() noexcept override {
        canceled_.store(true);
    }
private:
    template<typename Operation>
    auto Await(Operation operation, std::chrono::steady_clock::time_point deadline) {
        while (operation.Status() == winrt::Windows::Foundation::AsyncStatus::Started) {
            if (canceled_.load() || std::chrono::steady_clock::now() >= deadline) {
                operation.Cancel();
                throw std::runtime_error("HTTP request canceled or timed out.");
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(20));
        }
        return operation.GetResults();
    }
    std::chrono::milliseconds timeout_;
    std::atomic_bool canceled_{false};
};
}
std::unique_ptr<HttpClient> MakeWindowsHttpClient(std::chrono::milliseconds timeout) {
    return std::make_unique<WindowsHttpClient>(timeout);
}
}
