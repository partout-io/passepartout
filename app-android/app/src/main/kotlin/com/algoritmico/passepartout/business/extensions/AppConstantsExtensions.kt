// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import com.algoritmico.passepartout.business.models.AppConstantsEmails
import com.algoritmico.passepartout.business.models.AppConstantsGithub
import com.algoritmico.passepartout.business.models.AppConstantsTunnel
import com.algoritmico.passepartout.business.models.AppConstantsTunnelVerificationParameters
import com.algoritmico.passepartout.business.models.AppConstantsWebsites

val AppConstantsWebsites.apiURL: String
    get() = homeURL.appendingPath("api")

val AppConstantsWebsites.faqURL: String
    get() = homeURL.appendingPath("faq")

val AppConstantsWebsites.blogURL: String
    get() = homeURL.appendingPath("blog")

val AppConstantsWebsites.disclaimerURL: String
    get() = homeURL.appendingPath("disclaimer")

val AppConstantsWebsites.privacyPolicyURL: String
    get() = homeURL.appendingPath("privacy")

val AppConstantsWebsites.donateURL: String
    get() = homeURL.appendingPath("donate")

val AppConstantsWebsites.configURL: String
    get() = homeURL.appendingPath("config/v1/bundle.json")

val AppConstantsWebsites.betaConfigURL: String
    get() = homeURL.appendingPath("config/v1/bundle-beta.json")

fun AppConstantsGithub.urlForIssue(issue: Int): String {
    return issuesURL.appendingPath(issue.toString())
}

fun AppConstantsGithub.urlForChangelog(version: String): String {
    return rawURL.appendingPath("refs/tags/v$version/CHANGELOG.txt")
}

val AppConstantsEmails.issues: String
    get() = email(to = recipients.issues)

val AppConstantsEmails.beta: String
    get() = email(to = recipients.beta)

fun AppConstantsTunnel.verificationDelayMinutes(isBeta: Boolean): Int {
    return (verificationParameters(isBeta).delay / 60.0).toInt()
}

fun AppConstantsTunnel.verificationParameters(
    isBeta: Boolean
): AppConstantsTunnelVerificationParameters {
    return if (isBeta) {
        verification.beta
    } else {
        verification.production
    }
}

val AppConstantsTunnelVerificationParameters.delay: Double
    get() = defaultDelay

private fun AppConstantsEmails.email(to: String): String {
    return "$to@$domain"
}

private fun String.appendingPath(path: String): String {
    return trimEnd('/') + "/" + path.trimStart('/')
}
