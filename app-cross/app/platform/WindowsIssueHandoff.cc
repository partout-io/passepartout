// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "WindowsIssueHandoff.h"
#include <windows.h>
#include <mapi.h>
#include <winrt/base.h>

namespace Passepartout {
bool ReviewWindowsIssue(const IssueReport &report) {
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
    auto recipient = std::wstring(winrt::to_hstring("SMTP:" + report.recipient));
    auto subject = std::wstring(winrt::to_hstring(report.subject));
    auto comment = std::wstring(winrt::to_hstring(report.comment));
    MapiRecipDescW address{};
    address.ulRecipClass = MAPI_TO;
    address.lpszAddress = recipient.data();
    std::vector<std::wstring> paths;
    for (const auto &path : report.attachments) paths.push_back(path.wstring());
    std::vector<MapiFileDescW> files;
    for (auto &path : paths) {
        MapiFileDescW file{};
        file.nPosition = static_cast<ULONG>(-1);
        file.lpszPathName = path.data();
        files.push_back(file);
    }
    MapiMessageW message{};
    message.lpszSubject = subject.data();
    message.lpszNoteText = comment.data();
    message.nRecipCount = 1;
    message.lpRecips = &address;
    message.nFileCount = static_cast<ULONG>(files.size());
    message.lpFiles = files.data();
    // MAPI_DIALOG is mandatory: the user reviews and decides whether to send.
    const auto result = send(0, 0, &message, MAPI_DIALOG | MAPI_LOGON_UI, 0);
    return result == SUCCESS_SUCCESS || result == MAPI_E_USER_ABORT;
}
}
