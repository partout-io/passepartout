// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "AppConstantsExtensions.h"

namespace {
std::string AppendingPath(const std::string &base, const std::string &path) {
    const auto end = base.find_last_not_of('/');
    const auto start = path.find_first_not_of('/');
    return base.substr(0, end == std::string::npos ? 0 : end + 1) + "/" +
        (start == std::string::npos ? std::string() : path.substr(start));
}
}

namespace Passepartout::Constants {
std::chrono::milliseconds HTTPTimeout(const Models::AppConstants_url &url) {
    return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::duration<double>(url.timeoutInterval));
}

std::chrono::seconds ConfigTTL(const Models::AppConstants_websites &websites) {
    return std::chrono::duration_cast<std::chrono::seconds>(std::chrono::duration<double>(websites.configTTL));
}

std::string ConfigURL(const Models::AppConstants_websites &websites) {
    return AppendingPath(websites.partoutURL, "passepartout-config/v1/bundle.json");
}

std::string BlogURL(const Models::AppConstants_websites &websites) {
    return AppendingPath(websites.partoutURL, "blog");
}

std::string FAQURL(const Models::AppConstants_websites &websites) {
    return AppendingPath(websites.homeURL, "faq");
}

std::string DisclaimerURL(const Models::AppConstants_websites &websites) {
    return AppendingPath(websites.homeURL, "disclaimer");
}

std::string PrivacyPolicyURL(const Models::AppConstants_websites &websites) {
    return AppendingPath(websites.homeURL, "privacy");
}

std::string IssueURL(const Models::AppConstants_github &github, int32_t issue) {
    return AppendingPath(github.issuesURL, std::to_string(issue));
}

std::string ChangelogURL(const Models::AppConstants_github &github, const std::string &build) {
    return AppendingPath(github.rawURL, "refs/tags/builds/" + build + "/app-cross/CHANGELOG.txt");
}

std::string IssuesEmail(const Models::AppConstants_emails &emails) {
    return emails.recipients.issues + "@" + emails.domain;
}

std::string BetaEmail(const Models::AppConstants_emails &emails) {
    return emails.recipients.beta + "@" + emails.domain;
}
}
