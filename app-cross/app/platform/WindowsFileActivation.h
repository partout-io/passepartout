// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/FileActivation.h"

namespace Passepartout {
class WindowsFileActivation {
public:
    WindowsFileActivation(const std::wstring &service, FileActivation::Handler handler);
    ~WindowsFileActivation();
    static bool Forward(const std::wstring &service, std::shared_ptr<const ConfigurationFiles> files);
private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};
// Call once early on the UI thread. Brokered files are read later on a worker.
std::shared_ptr<const ConfigurationFiles> ReadWindowsActivationFiles();
}
