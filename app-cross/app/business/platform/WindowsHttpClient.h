// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../strategy/HttpClient.h"
#include <chrono>

namespace Passepartout::Windows {
std::unique_ptr<HttpClient> MakeHttpClient(std::chrono::milliseconds timeout);
}
