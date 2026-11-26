// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import com.algoritmico.passepartout.models.Issue
import com.algoritmico.passepartout.ui.Strings

fun Issue.body(template: String): String {
    val fields = mapOf(
        "comment" to comment,
        "appLine" to (appLine ?: "unknown"),
        "osLine" to osLine,
        "deviceLine" to (deviceLine ?: "unknown"),
        "purchasedProducts" to purchasedProducts.issueDescription()
    )
    return Regex("""\$([A-Za-z]+)""").replace(template) { match ->
        fields[match.groupValues[1]] ?: match.value
    }
}

val Issue.subject: String
    get() = Strings.Unlocalized.Issues.subject

private fun List<String>.issueDescription(): String {
    return joinToString(prefix = "[", postfix = "]") {
        "\"$it\""
    }
}
