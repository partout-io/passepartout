// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import com.algoritmico.passepartout.models.Issue
import com.algoritmico.passepartout.ui.Strings

val Issue.body: String
    get() {
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
            appendLine()
            appendLine("--")
            appendLine()
            appendLine("Regards")
            appendLine()
        }
    }

val Issue.subject: String
    get() = Strings.Unlocalized.Issues.subject

private fun List<String>.issueDescription(): String {
    return joinToString(prefix = "[", postfix = "]") {
        "\"$it\""
    }
}
