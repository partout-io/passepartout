// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "Profile.h"
#include <algorithm>
#include <cctype>
#include <fstream>
#include <stdexcept>
#include <limits>
#include <locale>
#include <codecvt>
#include <cmath>
#ifdef _WIN32
#include <windows.h>
#endif

namespace {
std::wstring LowerName(const std::string &name) {
#ifdef _WIN32
    if (name.empty()) return {};
    const int wide_size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, name.data(), static_cast<int>(name.size()), nullptr, 0);
    if (!wide_size) throw std::runtime_error("Invalid UTF-8 profile name.");
    std::wstring wide(wide_size, L'\0');
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, name.data(), static_cast<int>(name.size()), wide.data(), wide_size);
#else
    std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
    auto wide = converter.from_bytes(name);
#endif
#ifdef _WIN32
    if (wide.empty()) return wide;
    const int size = LCMapStringEx(LOCALE_NAME_INVARIANT, LCMAP_LOWERCASE,
        wide.data(), static_cast<int>(wide.size()), nullptr, 0, nullptr, nullptr, 0);
    if (!size) throw std::runtime_error("Unable to order profile names.");
    std::wstring lower(size, L'\0');
    LCMapStringEx(LOCALE_NAME_INVARIANT, LCMAP_LOWERCASE,
        wide.data(), static_cast<int>(wide.size()), lower.data(), size, nullptr, nullptr, 0);
    return lower;
#else
    static const std::locale locale("");
    const auto &facet = std::use_facet<std::ctype<wchar_t>>(locale);
    if (!wide.empty()) facet.tolower(wide.data(), wide.data() + wide.size());
    return wide;
#endif
}

double LastUpdate(const Passepartout::Profile &profile) {
    if (profile.userInfo && profile.userInfo->IsObject()) {
        const auto value = profile.userInfo->Find("lastUpdate");
        if (value) {
            if (value->IsNumber()) return value->Get<double>();
            if (value->IsString()) {
                try {
                    std::size_t length;
                    const auto text = value->Get<std::string>();
                    const auto number = std::stod(text, &length);
                    if (length == text.size() && std::isfinite(number)) return number;
                } catch (...) {}
            }
        }
    }
    return -std::numeric_limits<double>::infinity();
}
}

std::string Passepartout::ConfigurationName(const std::filesystem::path &path) {
    const auto name = path.stem().u8string();
    return std::string(reinterpret_cast<const char *>(name.data()), name.size());
}

bool Passepartout::IsSafeProfileId(const std::string &id) {
    auto upper = id;
    std::transform(upper.begin(), upper.end(), upper.begin(), [](unsigned char c) {
        return static_cast<char>(std::toupper(c));
    });
    if (upper == "CON" || upper == "PRN" || upper == "AUX" || upper == "NUL" ||
        (upper.size() == 4 && (upper.substr(0, 3) == "COM" || upper.substr(0, 3) == "LPT") &&
         upper[3] >= '0' && upper[3] <= '9')) return false;
    return !id.empty() && id.size() <= 128 &&
        std::all_of(id.begin(), id.end(), [](unsigned char c) {
            return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                (c >= '0' && c <= '9') || c == '-' || c == '_';
        });
}

void Passepartout::SortProfiles(std::vector<Profile> &profiles) {
    std::sort(profiles.begin(), profiles.end(), [](const auto &a, const auto &b) {
        const auto left = LowerName(a.name);
        const auto right = LowerName(b.name);
        if (left != right) return left < right;
        const auto left_date = LastUpdate(a);
        const auto right_date = LastUpdate(b);
        if (left_date != right_date) return left_date > right_date;
        return a.id < b.id;
    });
}

void Passepartout::ValidateProfileIdentity(const Profile &profile) {
    if (!IsSafeProfileId(profile.id) || profile.name.empty())
        throw std::runtime_error("The profile has an invalid identity or an empty name.");
}

std::string Passepartout::ReadConfiguration(const std::filesystem::path &path) {
    if (!std::filesystem::is_regular_file(path))
        throw std::runtime_error("The configuration is not a regular file.");
    std::ifstream input(path, std::ios::binary);
    if (!input) throw std::runtime_error("Unable to open the configuration file.");
    // Bound the actual read, including files that grow after opening.
    std::string content(MaxConfigurationBytes + 1, '\0');
    input.read(content.data(), static_cast<std::streamsize>(content.size()));
    const auto size = input.gcount();
    if (input.bad() || size <= 0 || size > static_cast<std::streamsize>(MaxConfigurationBytes))
        throw std::runtime_error("The configuration must be a nonempty file no larger than 1 MiB.");
    content.resize(static_cast<std::size_t>(size));
    if (content.find('\0') != std::string::npos)
        throw std::runtime_error("The configuration contains invalid text.");
    return content;
}
