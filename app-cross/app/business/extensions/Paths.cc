// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "Paths.h"
#ifdef _WIN32
#include <windows.h>
#include <limits>
#include <stdexcept>
#include <system_error>
#endif

namespace Passepartout::Paths {
std::filesystem::path FromUtf8(const std::string &value) {
#ifdef _WIN32
    if (value.empty()) return {};
    if (value.size() > static_cast<std::size_t>((std::numeric_limits<int>::max)())) {
        throw std::length_error("Path is too long.");
    }
    const auto length = static_cast<int>(value.size());
    const auto size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(), length, nullptr, 0);
    if (!size) throw std::system_error(GetLastError(), std::system_category());
    std::wstring native(size, L'\0');
    if (!MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(), length, native.data(), size)) {
        throw std::system_error(GetLastError(), std::system_category());
    }
    return std::filesystem::path(native);
#else
    return std::filesystem::path(value);
#endif
}
}
