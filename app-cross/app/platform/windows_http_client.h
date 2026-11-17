// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/http_client.h"
#include <chrono>

namespace Passepartout {
std::unique_ptr<HttpClient> MakeWindowsHttpClient(std::chrono::milliseconds timeout);
}
