// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../strategy/HttpClient.h"
#include <chrono>

namespace Passepartout {
std::unique_ptr<HttpClient> MakeWindowsHttpClient(std::chrono::milliseconds timeout);
}
