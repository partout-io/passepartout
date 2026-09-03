// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import com.algoritmico.passepartout.models.AppConstantsEmails
import com.algoritmico.passepartout.models.AppConstantsGithub
import com.algoritmico.passepartout.models.AppConstantsTunnel
import com.algoritmico.passepartout.models.AppConstantsTunnelVerificationParameters
import com.algoritmico.passepartout.models.AppConstantsWebsites

//region Partout
val AppConstantsWebsites.blogURL: String
    get() = partoutURL.appendingPath("blog")

val AppConstantsWebsites.donateURL: String
    get() = partoutURL.appendingPath("donate")

val AppConstantsWebsites.configURL: String
    get() = partoutURL.appendingPath("passepartout-config/v1/bundle.json")

//endregion

//region Passepartout
val AppConstantsWebsites.disclaimerURL: String
    get() = homeURL.appendingPath("disclaimer")

val AppConstantsWebsites.faqURL: String
    get() = homeURL.appendingPath("faq")

val AppConstantsWebsites.privacyPolicyURL: String
    get() = homeURL.appendingPath("privacy")
//endregion

fun AppConstantsGithub.urlForIssue(issue: Int): String {
    return issuesURL.appendingPath(issue.toString())
}

fun AppConstantsGithub.urlForChangelog(build: String): String {
    return rawURL.appendingPath("refs/tags/builds/$build/app-android/CHANGELOG.txt")
}

val AppConstantsEmails.issues: String
    get() = email(to = recipients.issues)

val AppConstantsEmails.beta: String
    get() = email(to = recipients.beta)

val AppConstantsTunnel.verificationDelayMinutes: Int
    get() = (verification.production.delay / 60.0).toInt()

val AppConstantsTunnelVerificationParameters.delay: Double
    get() = defaultDelay

private fun AppConstantsEmails.email(to: String): String {
    return "$to@$domain"
}

private fun String.appendingPath(path: String): String {
    return trimEnd('/') + "/" + path.trimStart('/')
}
