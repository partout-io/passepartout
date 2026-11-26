// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "IssueReporter.h"
#include "../extensions/ModelsExtensions.h"
#include <random>
#include <stdexcept>

namespace Passepartout {
IssueReporter::IssueReporter(std::string recipient, std::string version, Handoff handoff)
    : recipient_(std::move(recipient)), version_(std::move(version)), handoff_(std::move(handoff)) {}

bool IssueReporter::Report(const std::string &comment, const std::string &runtime_log) {
    if (comment.size() > 64 * 1024) throw std::invalid_argument("The comment is too long.");
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
    const auto metadata = directory / "application.txt";
    AtomicFile::Write(metadata, "Passepartout " + version_ + "\nPlatform: Windows\nCrypto: mbedTLS\n"
        "Tunnel runtime log: unavailable in frontend process\n");
    IssueReport report{recipient_, "Passepartout " + version_, comment, {metadata}};
    if (!runtime_log.empty()) {
        const auto log = directory / "runtime.txt";
        AtomicFile::Write(log, runtime_log);
        report.attachments.push_back(log);
    }
    return handoff_(report);
}
}
