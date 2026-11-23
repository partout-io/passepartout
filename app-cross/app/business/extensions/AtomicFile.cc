// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "AtomicFile.h"
#include <cerrno>
#include <cstdio>
#include <stdexcept>
#include <random>
#include <sstream>
#include <iomanip>
#ifdef _WIN32
#include <windows.h>
#else
#include <fcntl.h>
#include <unistd.h>
#endif

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
