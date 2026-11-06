// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import com.algoritmico.passepartout.business.extensions.GenericException
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.context.AppLogBackend
import com.algoritmico.passepartout.context.AppLogLevel
import com.algoritmico.passepartout.context.NoOpAppLogBackend
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.observables.ProfileImporterException
import com.algoritmico.passepartout.observables.TunnelObservableException
import com.algoritmico.passepartout.observables.asAppError
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.mutablePreferencesOf
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.runBlocking
import io.partout.models.OpenVPNCredentials
import io.partout.models.OpenVPNCredentialsOTPMethod
import io.partout.models.OpenVPNModule
import io.partout.models.TaggedModuleOpenVPN
import io.partout.models.TaggedProfile
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class ErrorLoggingUnitTest {
    @Test
    fun appLogProtectsSensitiveNestedExceptionsAtEveryLevel() {
        data class Entry(val level: AppLogLevel, val tag: String, val message: String, val error: Throwable?)
        val entries = mutableListOf<Entry>()
        val recordingBackend = object : AppLogBackend {
            override fun log(level: AppLogLevel, tag: String, message: String, error: Throwable?) {
                entries.add(Entry(level, tag, message, error))
            }
        }
        val nested = IllegalArgumentException("private-parser-input")
        val failure = GenericException("private-wrapper-message", nested)
        val previous = AppLog.logsPrivateData
        val previousBackend = AppLog.setBackend(recordingBackend)
        try {
            for (enabled in listOf(false, true, false)) {
                AppLog.logsPrivateData = enabled
                entries.clear()
                AppLog.d("test", "Operation failed", failure)
                AppLog.i("test", "Operation failed", failure)
                AppLog.w("test", "Operation failed", failure)
                AppLog.e("test", "Operation failed", failure)
                assertEquals(AppLogLevel.entries.toList(), entries.map { it.level })
                for (entry in entries) {
                    assertEquals("test", entry.tag)
                    if (enabled) {
                        assertEquals("Operation failed", entry.message)
                        assertSame(failure, entry.error)
                    } else {
                        assertEquals("Operation failed (${failure.javaClass.name})", entry.message)
                        assertNull(entry.error)
                    }
                    val output = entry.message + (entry.error?.stackTraceToString() ?: "")
                    assertEquals(enabled, output.contains("private-parser-input"))
                    assertEquals(enabled, output.contains("private-wrapper-message"))
                }
                AppLog.i("test", "Plain message")
                assertEquals(Entry(AppLogLevel.INFO, "test", "Plain message", null), entries.last())
                for (error in listOf(nested, failure)) {
                    entries.clear()
                    runCatchingNonFatal { throw error }.onFailure { assertSame(error, it) }
                    val entry = entries.single()
                    assertEquals(AppLogLevel.DEBUG, entry.level)
                    if (enabled) {
                        assertSame(error, entry.error)
                    } else {
                        assertNull(entry.error)
                    }
                    val output = entry.message + (entry.error?.stackTraceToString() ?: "")
                    assertEquals(enabled, output.contains("private-parser-input"))
                    assertEquals(enabled && error === failure, output.contains("private-wrapper-message"))
                }
                assertSame(nested, failure.cause)
                assertEquals("private-parser-input", nested.message)
            }
        } finally {
            AppLog.logsPrivateData = previous
            AppLog.setBackend(previousBackend)
        }
    }

    @Test
    fun loggingPreferenceIsLoadedAndUpdated() = runBlocking {
        val values = MutableStateFlow<Preferences>(
            mutablePreferencesOf(booleanPreferencesKey(AppPreferenceKey.logsPrivateData.name) to true)
        )
        val store = object : DataStore<Preferences> {
            override val data = values
            override suspend fun updateData(transform: suspend (Preferences) -> Preferences): Preferences {
                return transform(values.value).also { values.value = it }
            }
        }
        val scope = CoroutineScope(Dispatchers.Unconfined + SupervisorJob())
        val previous = AppLog.logsPrivateData
        val previousBackend = AppLog.setBackend(NoOpAppLogBackend)
        try {
            UserPreferencesObservable("test", scope, store).use { preferences ->
                assertTrue(AppLog.logsPrivateData)
                for (enabled in listOf(false, true, false)) {
                    preferences.updatePreferences(listOf(AppPreferenceKey.logsPrivateData)) {
                        it.copy(logsPrivateData = enabled)
                    }
                    assertEquals(enabled, AppLog.logsPrivateData)
                }
            }
        } finally {
            scope.cancel()
            AppLog.logsPrivateData = previous
            AppLog.setBackend(previousBackend)
        }
    }

    @Test
    fun richErrorsAndStackTracesFollowPrivateDataPreference() {
        val credentials = OpenVPNCredentials("private-user", "private-password", OpenVPNCredentialsOTPMethod.none)
        val profile = TaggedProfile(
            id = "profile-id", name = "private-name",
            modules = listOf(TaggedModuleOpenVPN(OpenVPNModule(id = "module-id", credentials = credentials))),
            activeModulesIds = setOf("module-id")
        )
        val interactive = TunnelObservableException.Interactive(profile)
        val generic = GenericException("private-message", interactive)
        val failure = ProfileImporterException.Failure(generic)
        val previous = AppLog.logsPrivateData
        try {
            for (enabled in listOf(false, true, false)) {
                AppLog.logsPrivateData = enabled
                val descriptions = listOf(
                    "$interactive", "${interactive.asAppError}", "$generic", "$failure",
                    interactive.stackTraceToString(), failure.stackTraceToString()
                )
                for (description in descriptions) {
                    assertEquals(enabled, description.contains("private-password"))
                    assertEquals(enabled, description.contains("private-user"))
                    assertEquals(enabled, description.contains("private-name"))
                }
                assertEquals(enabled, generic.toString().contains("private-message"))
                assertTrue(interactive.toString().contains("profile-id"))
                assertSame(profile, interactive.profile)
                assertSame(generic, failure.cause)
                assertEquals("private-message", generic.message)
            }
        } finally {
            AppLog.logsPrivateData = previous
        }
    }
}
