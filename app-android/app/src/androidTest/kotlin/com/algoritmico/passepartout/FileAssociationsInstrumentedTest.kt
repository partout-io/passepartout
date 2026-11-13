// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class FileAssociationsInstrumentedTest {
    @Test
    fun associationsRespectPlatformSuffixSupport() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        fun resolve(extension: String, type: String? = null) = context.packageManager.resolveActivity(
            Intent(Intent.ACTION_VIEW)
                .setDataAndType(Uri.parse("file:///test/profile.$extension"), type)
                .setPackage(context.packageName),
            PackageManager.MATCH_DEFAULT_ONLY
        )
        for (extension in listOf("ovpn", "conf", "json")) {
            assertEquals(Build.VERSION.SDK_INT >= 31, resolve(extension) != null)
        }
        assertNull(resolve("pdf"))
        assertNotNull(resolve("json", "application/json"))
        assertNotNull(resolve("conf", "text/plain"))
        assertNotNull(resolve("ovpn", "application/x-openvpn-profile"))
    }
}
