// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.extensions.body
import com.algoritmico.passepartout.models.Issue
import java.util.UUID
import org.junit.Assert.assertEquals
import org.junit.Test

class IssueExtensionsUnitTest {
    @Test
    fun body_preservesPlaceholderTextInCommentsAndFormatsMetadata() {
        val issue = Issue(
            id = UUID.randomUUID(),
            comment = "café 日本語 \$osLine",
            purchasedProducts = listOf("premium"),
            attachments = emptyList(),
            osLine = "Android"
        )
        val template = "\$comment|\$appLine|\$osLine|\$deviceLine|\$purchasedProducts|\$unknown"
        assertEquals(
            "café 日本語 \$osLine|unknown|Android|unknown|[\"premium\"]|\$unknown",
            issue.body(template)
        )
    }
}
