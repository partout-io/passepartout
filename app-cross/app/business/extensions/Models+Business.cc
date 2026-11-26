// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "Models+Business.h"
#include "partout.h"
#include <algorithm>
#include <type_traits>
#include <cctype>
#include <fstream>
#include <stdexcept>
#include <limits>
#include <locale>
#include <codecvt>
#include <cmath>
#ifdef _WIN32
#include <windows.h>
#include <system_error>
#else
#include <fcntl.h>
#include <unistd.h>
#endif
#include <cerrno>
#include <cstdio>
#include <random>
#include <regex>
#include <sstream>
#include <iomanip>

namespace {
std::wstring LowerName(const std::string &name) {
#ifdef _WIN32
    if (name.empty()) return {};
    const int wide_size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, name.data(), static_cast<int>(name.size()), nullptr, 0);
    if (!wide_size) throw std::runtime_error("Invalid UTF-8 name.");
    std::wstring wide(wide_size, L'\0');
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, name.data(), static_cast<int>(name.size()), wide.data(), wide_size);
    if (wide.empty()) return wide;
    const int size = LCMapStringEx(LOCALE_NAME_INVARIANT, LCMAP_LOWERCASE,
        wide.data(), static_cast<int>(wide.size()), nullptr, 0, nullptr, nullptr, 0);
    if (!size) throw std::runtime_error("Unable to order names.");
    std::wstring lower(size, L'\0');
    LCMapStringEx(LOCALE_NAME_INVARIANT, LCMAP_LOWERCASE,
        wide.data(), static_cast<int>(wide.size()), lower.data(), size, nullptr, nullptr, 0);
    return lower;
#else
    std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
    auto wide = converter.from_bytes(name);
    static const std::locale locale("");
    const auto &facet = std::use_facet<std::ctype<wchar_t>>(locale);
    if (!wide.empty()) facet.tolower(wide.data(), wide.data() + wide.size());
    return wide;
#endif
}

double LastUpdate(const Passepartout::Profile &profile) {
    if (profile.userInfo && profile.userInfo->IsObject()) {
        const auto value = profile.userInfo->Find(Passepartout::Profiles::LastUpdateKey);
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

using Passepartout::Models::AppTunnelInfo;
using Passepartout::Models::ProfileTransfer;

std::string Passepartout::Profiles::ConfigurationName(const std::filesystem::path &path) {
    const auto name = path.stem().u8string();
    return std::string(reinterpret_cast<const char *>(name.data()), name.size());
}

bool Passepartout::Profiles::IsSafeId(const std::string &id) {
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

std::optional<Passepartout::InteractiveLogin> Passepartout::Profiles::InteractiveLoginFor(const Profile &profile) {
    for (const auto &tagged : profile.modules) {
        const auto *openvpn = std::get_if<Partout::Models::TaggedModuleOpenVpn>(&tagged);
        if (!openvpn) continue;
        const auto &module = openvpn->value;
        if (std::find(profile.activeModulesIds.begin(), profile.activeModulesIds.end(), module.id) == profile.activeModulesIds.end()) continue;
        const auto &saved = module.credentials;
        const bool missing = !saved || (saved->username.empty() && saved->password.empty());
        if (!module.requiresInteractiveCredentials.value_or(false) &&
            !(module.configuration && (module.configuration->staticChallenge.value_or(false) ||
                (module.configuration->authUserPass.value_or(false) && missing)))) continue;
        Passepartout::InteractiveLogin login{};
        login.original = profile;
        if (saved) {
            login.credentials = {saved->username, saved->password};
            login.needs_otp = saved->otpMethod.value != Partout::Models::OpenVpnCredentialsOTPMethod::none;
        }
        // The native adapter receives the raw OTP; Partout applies its encoding.
        if (login.needs_otp) login.credentials.password.clear();
        return login;
    }
    return std::nullopt;
}

void Passepartout::Profiles::Sort(std::vector<Profile> &profiles) {
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

void Passepartout::Profiles::ValidateIdentity(const Profile &profile) {
    if (!IsSafeId(profile.id) || profile.name.empty())
        throw std::runtime_error("The profile has an invalid identity or an empty name.");
}

std::string Passepartout::Profiles::ReadConfiguration(const std::filesystem::path &path) {
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

namespace Passepartout {
Models::AppPreferences Preferences::Defaults() {
    Models::AppPreferences preferences{};
    preferences.dnsFallsBack = true;
    preferences.cryptoBackend = PartoutCryptoMbedTLS;
    return preferences;
}

Models::AppPreferences Preferences::FromJson(const Partout::Json &data) {
    if (!data.IsObject()) throw std::runtime_error("Invalid preferences.");
    const auto defaults = Defaults();
    auto merged = defaults.ToJson();
    merged.Merge(data);
    auto preferences = Models::AppPreferences::FromJson(merged);
    preferences.cryptoBackend = defaults.cryptoBackend;
    return preferences;
}

void Credits::Sort(Models::Credits &credits) {
    const auto by_name = [](const auto &left, const auto &right) {
        return LowerName(left.name) < LowerName(right.name);
    };
    std::stable_sort(credits.licenses.begin(), credits.licenses.end(), by_name);
    std::stable_sort(credits.notices.begin(), credits.notices.end(), by_name);
}

void Credits::Filter(Models::Credits &credits, Models::Platform::ePlatform platform) {
    auto &licenses = credits.licenses;
    licenses.erase(std::remove_if(licenses.begin(), licenses.end(), [platform](const auto &license) {
        return license.platforms && std::none_of(license.platforms->begin(), license.platforms->end(), [platform](const auto &value) {
            return value.value == platform;
        });
    }), licenses.end());
}
}

std::vector<AppTunnelInfo> Passepartout::Tunnels::Info(const std::vector<Partout::Models::TunnelSnapshot> &snapshots) {
    std::vector<AppTunnelInfo> result;
    for (const auto &snapshot : snapshots) {
        AppTunnelInfo info{};
        info.id = snapshot.id;
        info.isEnabled = snapshot.isEnabled;
        info.onDemand = snapshot.onDemand;
        if (snapshot.environment) {
            ProfileTransfer transfer{};
            transfer.received = snapshot.environment->dataCount.received;
            transfer.sent = snapshot.environment->dataCount.sent;
            info.transfer = transfer;
            info.lastErrorCode = snapshot.environment->lastErrorCode;
        }
        switch (snapshot.status.value) {
            case Partout::Models::TunnelStatus::inactive:
                info.status.value = Status::disconnected;
                break;
            case Partout::Models::TunnelStatus::activating:
                info.status.value = Status::connecting;
                break;
            case Partout::Models::TunnelStatus::active:
                info.status.value = Status::connected;
                break;
            case Partout::Models::TunnelStatus::deactivating:
                info.status.value = Status::disconnecting;
                break;
            default:
                throw std::runtime_error("Unknown tunnel status.");
        }
        result.push_back(std::move(info));
    }
    return result;
}

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

namespace Passepartout {
void AtomicFile::Write(const std::filesystem::path &path, const std::string &content) {
    std::random_device random;
    std::ostringstream uuid;
    uuid << std::hex << std::setfill('0');
    for (int i = 0; i < 16; ++i) {
        if (i == 4 || i == 6 || i == 8 || i == 10) uuid << '-';
        auto byte = random() & 0xff;
        if (i == 6) byte = (byte & 0x0f) | 0x40;
        if (i == 8) byte = (byte & 0x3f) | 0x80;
        uuid << std::setw(2) << byte;
    }
    const auto temporary = path.parent_path() / (uuid.str() + ".tmp");
    // Never delete the destination before replacement; failure leaves the last
    // committed file intact. The caller serializes writes to the same path.
#ifdef _WIN32
    HANDLE file = CreateFileW(temporary.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_NEW,
                             FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) throw std::runtime_error("Unable to save the file.");
    DWORD written = 0;
    const bool success = WriteFile(file, content.data(), static_cast<DWORD>(content.size()), &written, nullptr)
        && written == content.size() && FlushFileBuffers(file);
    CloseHandle(file);
    if (!success || !MoveFileExW(temporary.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
        DeleteFileW(temporary.c_str());
        throw std::runtime_error("Unable to replace the saved file.");
    }
#else
    const int file = open(temporary.c_str(), O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600);
    if (file < 0) throw std::runtime_error("Unable to save the file.");
    std::size_t offset = 0;
    while (offset < content.size()) {
        const auto written = write(file, content.data() + offset, content.size() - offset);
        if (written < 0 && errno == EINTR) continue;
        if (written <= 0) break;
        offset += static_cast<std::size_t>(written);
    }
    const bool success = offset == content.size() && fsync(file) == 0;
    close(file);
    if (!success || rename(temporary.c_str(), path.c_str()) != 0) {
        unlink(temporary.c_str());
        throw std::runtime_error("Unable to replace the saved file.");
    }
#endif
}

}

namespace Passepartout {
std::string Issues::Subject(const Models::Issue &issue) {
    return issue.appLine.value_or("Passepartout");
}

std::string Issues::Body(const Models::Issue &issue, const std::string &text) {
    std::ostringstream products;
    products << '[';
    for (size_t index = 0; index < issue.purchasedProducts.size(); ++index) {
        if (index) products << ", ";
        products << std::quoted(issue.purchasedProducts[index]);
    }
    products << ']';
    const std::regex placeholder(R"(\$([A-Za-z]+))");
    std::string body;
    size_t offset = 0;
    for (auto it = std::sregex_iterator(text.begin(), text.end(), placeholder);
         it != std::sregex_iterator(); ++it) {
        const auto &match = *it;
        body.append(text, offset, match.position() - offset);
        const auto field = match[1].str();
        if (field == "comment") body += issue.comment;
        else if (field == "appLine") body += issue.appLine.value_or("unknown");
        else if (field == "osLine") body += issue.osLine;
        else if (field == "deviceLine") body += issue.deviceLine.value_or("unknown");
        else if (field == "purchasedProducts") body += products.str();
        else body += match.str();
        offset = match.position() + match.length();
    }
    body.append(text, offset, std::string::npos);
    return body;
}
}

namespace Passepartout::Changelogs {
std::vector<Models::ChangelogEntry> Parse(const std::string &text) {
    std::vector<Models::ChangelogEntry> entries;
    std::istringstream lines(text);
    std::string line;
    int32_t index = 0;
    while (std::getline(lines, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.empty()) continue;
        const auto id = index++;
        if (line.compare(0, 2, "* ") != 0) continue;
        std::istringstream words(line.substr(2));
        std::vector<std::string> components;
        std::string word;
        while (words >> word) components.push_back(word);
        Models::ChangelogEntry entry{};
        entry.id = id;
        if (components.size() >= 2) {
            const auto &last = components.back();
            if (last.size() > 3 && last.compare(0, 2, "(#") == 0 && last.back() == ')') {
                try {
                    const auto number = last.substr(2, last.size() - 3);
                    std::size_t count = 0;
                    const auto issue = std::stoi(number, &count);
                    if (count == number.size()) {
                        entry.issue = issue;
                        components.pop_back();
                    }
                } catch (const std::invalid_argument &) {
                } catch (const std::out_of_range &) {}
            }
        }
        for (const auto &component : components) {
            if (!entry.comment.empty()) entry.comment += " ";
            entry.comment += component;
        }
        entries.push_back(std::move(entry));
    }
    return entries;
}
}

namespace Passepartout::Profiles {
Models::AppProfileHeader Header(const Profile &profile) {
    Models::AppProfileHeader header{};
    header.id = profile.id;
    header.name = profile.name;
    header.fingerprint = profile.id;
    if (profile.userInfo && profile.userInfo->IsObject()) {
        const auto fingerprint = profile.userInfo->Find(Profiles::FingerprintKey);
        if (fingerprint && fingerprint->IsString())
            header.fingerprint = fingerprint->Get<std::string>();
    }
    for (const auto &module : profile.modules) {
        std::visit([&](const auto &value) {
            Partout::Models::ModuleType type;
            std::string id;
            if constexpr (std::is_same_v<std::decay_t<decltype(value)>, Partout::Models::TaggedModuleCustom>) {
                type = value.value.innerType;
                if (value.value.json.IsObject()) {
                    const auto field = value.value.json.Find("id");
                    if (field && field->IsString()) id = field->template Get<std::string>();
                }
            } else {
                type = Partout::Models::ModuleType::FromJson(value.type);
                id = value.value.id;
            }
            header.moduleTypes.push_back(type);
            if (!header.primaryModuleType && !id.empty() &&
                std::find(profile.activeModulesIds.begin(), profile.activeModulesIds.end(), id)
                    != profile.activeModulesIds.end()) header.primaryModuleType = type;
        }, module);
    }
    if (!header.primaryModuleType && !header.moduleTypes.empty())
        header.primaryModuleType = header.moduleTypes.front();
    for (const auto &type : header.moduleTypes) {
        if (!header.primaryModuleType || type != *header.primaryModuleType)
            header.secondaryModuleTypes.push_back(type);
    }
    return header;
}
}
