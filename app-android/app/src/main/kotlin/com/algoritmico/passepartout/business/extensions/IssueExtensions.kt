// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import com.algoritmico.passepartout.models.Issue
import java.text.DateFormat
import java.util.Date
import java.util.Locale

val Issue.body: String
    get() {
        val providers = providerLastUpdates.mapValues {
            timestampFormatter.format(Date(it.value))
        }
        return buildString {
            appendLine("Hi,")
            appendLine()
            appendLine(comment)
            appendLine()
            appendLine("--")
            appendLine()
            appendLine("App: ${appLine ?: "unknown"}")
            appendLine("OS: $osLine")
            appendLine("Device: ${deviceLine ?: "unknown"}")
            appendLine("Purchased: ${purchasedProducts.issueDescription()}")
            appendLine("Providers: ${providers.issueDescription()}")
            appendLine()
            appendLine("--")
            appendLine()
            appendLine("Regards")
            appendLine()
        }
    }

val Issue.subject: String
    get() = "Passepartout - Report issue"

private val timestampFormatter: DateFormat
    get() = DateFormat.getDateTimeInstance(
        DateFormat.MEDIUM,
        DateFormat.MEDIUM,
        Locale.getDefault()
    )

private fun List<String>.issueDescription(): String {
    return joinToString(prefix = "[", postfix = "]") {
        "\"$it\""
    }
}

private fun Map<String, String>.issueDescription(): String {
    if (isEmpty()) {
        return "[:]"
    }
    return entries.joinToString(prefix = "[", postfix = "]") {
        "\"${it.key}\": \"${it.value}\""
    }
}
