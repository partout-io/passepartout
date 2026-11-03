// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "app_context.h"
#include "import_result.h"
#include "partout.h"
#include <cstdlib>
#include <stdexcept>

namespace Passepartout {
namespace {
Profile ImportProfile(const std::string &text, const std::string &name) {
    std::unique_ptr<char, decltype(&std::free)> json(
        partout_import_profile(text.c_str(), name.c_str()), &std::free);
    return DecodeImportResult(json.get());
}
class UnavailableTunnelStrategy final : public TunnelStrategy {
public:
    std::vector<Models::AppTunnelInfo> Fetch() override {
        throw std::runtime_error("VPN control is only available in the Windows package. Use --demo for UI development.");
    }
    void Save(const Profile &) override {
        Fail();
    }
    void Connect(const std::string &) override {
        Fail();
    }
    void Disconnect(const std::string &) override {
        Fail();
    }
    void Remove(const std::string &) override {
        Fail();
    }
private:
    void Fail() {
        throw std::runtime_error("VPN control is unavailable.");
    }
};
std::unique_ptr<TunnelStrategy> MakeTunnel(bool demo) {
    if (demo) return std::make_unique<FakeTunnelStrategy>();
#ifdef _WIN32
    return MakeWindowsTunnelStrategy();
#else
    return std::make_unique<UnavailableTunnelStrategy>();
#endif
}
}
AppContext::AppContext(const std::filesystem::path &directory, bool demo)
    : session_(std::make_unique<AppSession>(std::make_unique<FileProfileRepository>(directory),
                                          ImportProfile, MakeTunnel(demo))),
      profiles(*session_), tunnel(*session_) {}
}
