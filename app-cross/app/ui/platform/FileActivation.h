// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../business/strategy/FileActivationInbox.h"
#include <string>

namespace Passepartout {
class FileActivation final {
public:
    FileActivation(const std::string &service, FileActivationInbox::Handler handler);
    ~FileActivation();
    static bool Forward(const std::string &service, std::shared_ptr<const ConfigurationFiles> files);
    // Call once early on the UI thread. Brokered files are read later on a worker.
    static std::shared_ptr<const ConfigurationFiles> ReadFiles();
private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};
}
