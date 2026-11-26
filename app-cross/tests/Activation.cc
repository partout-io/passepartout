// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "business/platform/FileActivationInbox.h"
#include "business/extensions/Models+Business.h"
#include "business/extensions/Models+Business.h"
#include <cassert>
#include <iostream>
#include "Support.h"

using namespace Passepartout;
int main() {
    InitializeTests();
    const auto unicode_path = Paths::FromUtf8("folder/Café 日本語.ovpn");
    assert(Paths::FromUtf8("").empty());
    assert(Profiles::ConfigurationName(unicode_path) == "Café 日本語");
    const MemoryConfigurationFiles files({{"Café 日本語", "line 1\nline 2"}, {"Broken", std::string(1, '\xff')}});
    const auto message = FileActivationInbox::Encode("request-1", files);
    FileActivationInbox inbox;
    std::shared_ptr<const ConfigurationFiles> owned;
    unsigned activations = 0;
    const auto handler = [&](auto files) {
        owned = std::move(files);
        ++activations;
        return true;
    };
    assert(inbox.Accept(message, handler));
    assert(owned->Count() == 1 && owned->selection_failures == 1);
    assert(owned->Read(0).name == "Café 日本語" && owned->Read(0).text == "line 1\nline 2");
    assert(inbox.Accept(message, handler) && activations == 1);
    assert(!inbox.Accept("invalid", handler));
    assert(!inbox.Accept(R"({"version":2,"id":"request-2","files":[],"failures":0})", handler));
    assert(!inbox.Accept(R"({"version":1,"id":"request-2","files":[],"failures":-1})", handler));
    const auto focus = FileActivationInbox::Encode("request-2", MemoryConfigurationFiles({}));
    assert(!inbox.Accept(focus, [](auto) { return false; }));
    assert(inbox.Accept(focus, handler) && activations == 2 && owned->Count() == 0);
    const MemoryConfigurationFiles invalid({{"Too large", std::string(1024 * 1024 + 1, 'x')}});
    assert(inbox.Accept(FileActivationInbox::Encode("request-3", invalid), handler));
    assert(!owned->Count() && owned->selection_failures == 1);
    std::cout << "Activation copying, Unicode, mixed failures, duplicates and retry passed.\n";
}
