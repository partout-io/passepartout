// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "WindowsIssueHandoff.h"
#include "../../business/extensions/ModelsExtensions.h"
#include "SettingsResources.h"
#include <random>
#include <stdexcept>
#include <windows.h>
#include <mapi.h>
#include <winrt/base.h>

namespace Passepartout {
bool Windows::Issue::Review(const std::string &recipient_address, const Models::Issue &issue) {
    const auto module = LoadLibraryExW(L"mapi32.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
    if (!module) return false;
    struct Library {
        HMODULE module;
        ~Library() {
            FreeLibrary(module);
        }
    } library{module};
    const auto send = reinterpret_cast<LPMAPISENDMAILW>(GetProcAddress(module, "MAPISendMailW"));
    if (!send) return false;
    std::random_device random;
    std::filesystem::path directory;
    for (int attempt = 0; attempt < 20; ++attempt) {
        auto candidate = std::filesystem::temp_directory_path() /
            ("passepartout-report-" + std::to_string(random()) + "-" + std::to_string(random()));
        if (std::filesystem::create_directory(candidate)) {
            directory = std::move(candidate);
            break;
        }
    }
    if (directory.empty()) throw std::runtime_error("Unable to prepare issue report.");
    struct Cleanup {
        std::filesystem::path directory;
        ~Cleanup() {
            std::error_code ignored;
            std::filesystem::remove_all(directory, ignored);
        }
    } cleanup{directory};
    auto recipient = std::wstring(winrt::to_hstring("SMTP:" + recipient_address));
    auto subject = std::wstring(winrt::to_hstring(issue.appLine.value_or("Passepartout")));
    auto body = std::wstring(winrt::to_hstring(Issues::Body(issue, IssueTemplateResource)));
    MapiRecipDescW address{};
    address.ulRecipClass = MAPI_TO;
    address.lpszAddress = recipient.data();
    std::vector<std::wstring> paths;
    for (const auto &attachment : issue.attachments) {
        const auto filename = Paths::FromUtf8(attachment.filename);
        if (filename.empty() || filename.has_parent_path() || filename == "." || filename == "..") {
            throw std::invalid_argument("Invalid issue attachment filename.");
        }
        const auto path = directory / filename;
        AtomicFile::Write(path, attachment.content);
        paths.push_back(path.wstring());
    }
    std::vector<MapiFileDescW> files;
    for (auto &path : paths) {
        MapiFileDescW file{};
        file.nPosition = static_cast<ULONG>(-1);
        file.lpszPathName = path.data();
        files.push_back(file);
    }
    MapiMessageW message{};
    message.lpszSubject = subject.data();
    message.lpszNoteText = body.data();
    message.nRecipCount = 1;
    message.lpRecips = &address;
    message.nFileCount = static_cast<ULONG>(files.size());
    message.lpFiles = files.data();
    // MAPI_DIALOG is mandatory: the user reviews and decides whether to send.
    const auto result = send(0, 0, &message, MAPI_DIALOG | MAPI_LOGON_UI, 0);
    return result == SUCCESS_SUCCESS || result == MAPI_E_USER_ABORT;
}
}
