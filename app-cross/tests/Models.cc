// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0
#include "../models/AppProfileHeader.h"
#include "../models/AppTunnelInfo.h"
#include "../models/Event.h"
#include "../models/Platform.h"
#include "../models/ProfileEventDelete.h"
#include "../models/ProfileEventSave.h"
#include <cassert>
#include <type_traits>

int main() {
    using namespace Passepartout::Models;
    using Partout::Json;
    static_assert(std::is_same_v<decltype(AppProfileHeader::moduleTypes),
        std::vector<Partout::Models::ModuleType>>);
    static_assert(std::is_same_v<decltype(ProfileEventSave::profile),
        Partout::Models::TaggedProfile>);

    const auto unixLikePlatform = Platform::FromJson("unixLike");
    assert(unixLikePlatform.value == Platform::unixLike);
    assert(unixLikePlatform.ToJson() == "unixLike");

    const auto input = Json::Parse(R"({
        "id":"example", "isEnabled":true, "status":"connected", "onDemand":false
    })");
    auto info = AppTunnelInfo::FromJson(input);
    assert(info.ToJson() == input);
    assert(!info.transfer.has_value());
    assert(!info.lastErrorCode.has_value());

    auto with_null = input;
    with_null.Set("lastErrorCode", nullptr);
    assert(!AppTunnelInfo::FromJson(with_null).lastErrorCode.has_value());

    const auto event = ProfileEventDelete::FromJson(
        {{"type", "ProfileEventDelete"}, {"ids", std::vector<std::string>{"example"}}});
    assert(event.ids == std::vector<std::string>{"example"});
    assert(event.ToJson().At("type") == "ProfileEventDelete");
    const auto decoded = event.ToJson().Get<Event>();
    assert(std::holds_alternative<ProfileEventDelete>(decoded));
    assert(Json(decoded) == event.ToJson());
    bool rejected = false;
    try {
        ProfileEventDelete::FromJson({{"type", "WrongEvent"}, {"ids", std::vector<std::string>{"example"}}});
    } catch (const std::exception &) {
        rejected = true;
    }
    assert(rejected);
}
