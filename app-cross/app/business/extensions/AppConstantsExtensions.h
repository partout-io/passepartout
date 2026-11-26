// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppConstants_websites.h"
#include "AppConstants_github.h"
#include "AppConstants_emails.h"
#include "AppConstants_url.h"
#include <chrono>
#include <string>

namespace Passepartout::Constants {
std::chrono::milliseconds HTTPTimeout(const Models::AppConstants_url &url);
std::chrono::seconds ConfigTTL(const Models::AppConstants_websites &websites);
std::string ConfigURL(const Models::AppConstants_websites &websites);
std::string BlogURL(const Models::AppConstants_websites &websites);
std::string FAQURL(const Models::AppConstants_websites &websites);
std::string DisclaimerURL(const Models::AppConstants_websites &websites);
std::string PrivacyPolicyURL(const Models::AppConstants_websites &websites);
std::string IssueURL(const Models::AppConstants_github &github, int32_t issue);
std::string ChangelogURL(const Models::AppConstants_github &github, const std::string &build);
std::string IssuesEmail(const Models::AppConstants_emails &emails);
std::string BetaEmail(const Models::AppConstants_emails &emails);
}
