// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.util.Log
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.MutablePreferences
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import com.algoritmico.passepartout.injection.JSON
import com.algoritmico.passepartout.injection.JSON.decode
import com.algoritmico.passepartout.injection.JSON.encode
import com.algoritmico.passepartout.managers.default
import com.algoritmico.passepartout.managers.update
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.models.ConfigFlag
import com.algoritmico.passepartout.models.ExperimentalPreferences
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking
import java.io.Closeable

class UserPreferencesObservable(
    private val logTag: String,
    coroutineScope: CoroutineScope,
    private val store: DataStore<Preferences>
) : Closeable {
    private val scope = CoroutineScope(
        coroutineScope.coroutineContext + SupervisorJob(coroutineScope.coroutineContext[Job])
    )

    private val flow: Flow<Preferences>
        get() {
            return store.data
        }

    val preferences: Flow<AppPreferences> = flow.map { it.toAppPreferences() }
    private var snapshot: AppPreferences

    init {
        snapshot = runBlocking {
            preferences.first()
        }
    }

    override fun close() {
        scope.cancel()
    }

    val currentPreferences: AppPreferences
        get() = snapshot

    val dnsFallback: Flow<Boolean> = preferences.map { it.dnsFallsBack }

    suspend fun toggleDnsFallback() {
        store.edit {
            val newValue = !(it[DNS_FALLS_BACK] ?: AppPreferences.default.dnsFallsBack)
            it[DNS_FALLS_BACK] = newValue
            snapshot = snapshot.copy(dnsFallsBack = newValue)
        }
        savePreferences()
    }

    suspend fun updateExperimentalPreferences(
        transform: (ExperimentalPreferences) -> ExperimentalPreferences
    ) {
        store.edit {
            val current = it[EXPERIMENTAL]?.decodePreference<ExperimentalPreferences>()
                ?: snapshot.experimental
            val newValue = transform(current)
            it[EXPERIMENTAL] = JSON.encode(newValue)
            snapshot = snapshot.copy(experimental = newValue)
        }
        savePreferences()
    }

    suspend fun updatePreferences(
        fields: List<AppPreferenceKey>,
        transform: (AppPreferences) -> AppPreferences
    ) {
        store.edit {
            val newValue = transform(snapshot)
            it.update(newValue, fields)
            snapshot = snapshot.update(newValue, fields)
        }
        savePreferences()
    }

    private fun savePreferences() {
        Log.d(logTag, "Preferences updated: $snapshot")
    }

    private fun Preferences.toAppPreferences(): AppPreferences {
        val default = AppPreferences.default
        return AppPreferences(
            configFlags = this[CONFIG_FLAGS]
                ?.mapNotNull { ConfigFlag.decode(it) }
                ?.toMutableList()
                ?: default.configFlags,
            dnsFallsBack = this[DNS_FALLS_BACK]
                ?: default.dnsFallsBack,
            experimental = this[EXPERIMENTAL]
                ?.decodePreference()
                ?: default.experimental,
            extensiveLogging = this[EXTENSIVE_LOGGING]
                ?: default.extensiveLogging,
            logsPrivateData = this[LOGS_PRIVATE_DATA]
                ?: default.logsPrivateData,
            newProfileEncoding = this[NEW_PROFILE_ENCODING]
                ?: default.newProfileEncoding,
            relaxedVerification = this[RELAXED_VERIFICATION]
                ?: default.relaxedVerification,
            skipsPurchases = this[SKIPS_PURCHASES]
                ?: default.skipsPurchases,
            deviceId = this[DEVICE_ID],
            lastCheckedVersionTimestamp = this[LAST_CHECKED_VERSION_DATE],
            lastCheckedVersion = this[LAST_CHECKED_VERSION],
            lastUsedProfileUUID = this[LAST_USED_PROFILE_ID]
        )
    }

    private fun MutablePreferences.update(new: AppPreferences, fields: List<AppPreferenceKey>) {
        fields.forEach {
            when (it) {
                AppPreferenceKey.deviceId ->
                    setOrRemove(
                        DEVICE_ID,
                        new.deviceId
                    )
                AppPreferenceKey.configFlags ->
                    this[CONFIG_FLAGS] = new.configFlags.map { it.value }.toSet()
                AppPreferenceKey.dnsFallsBack ->
                    this[DNS_FALLS_BACK] = new.dnsFallsBack
                AppPreferenceKey.experimental ->
                    this[EXPERIMENTAL] = JSON.encode(new.experimental)
                AppPreferenceKey.extensiveLogging ->
                    this[EXTENSIVE_LOGGING] = new.extensiveLogging
                AppPreferenceKey.lastCheckedVersion ->
                    setOrRemove(
                        LAST_CHECKED_VERSION,
                        new.lastCheckedVersion
                    )
                AppPreferenceKey.lastCheckedVersionDate ->
                    setOrRemove(
                        LAST_CHECKED_VERSION_DATE,
                        new.lastCheckedVersionTimestamp
                    )
                AppPreferenceKey.lastUsedProfileId ->
                    setOrRemove(
                        LAST_USED_PROFILE_ID,
                        new.lastUsedProfileUUID
                    )
                AppPreferenceKey.logsPrivateData ->
                    this[LOGS_PRIVATE_DATA] = new.logsPrivateData
                AppPreferenceKey.newProfileEncoding ->
                    this[NEW_PROFILE_ENCODING] = new.newProfileEncoding
                AppPreferenceKey.relaxedVerification ->
                    this[RELAXED_VERIFICATION] = new.relaxedVerification
                AppPreferenceKey.skipsPurchases ->
                    this[SKIPS_PURCHASES] = new.skipsPurchases
            }
        }
    }

    private fun <T> MutablePreferences.setOrRemove(key: Preferences.Key<T>, value: T?) {
        if (value == null) {
            remove(key)
            return
        }
        this[key] = value
    }

    private inline fun <reified T> String.decodePreference(): T? {
        return runCatching {
            JSON.decode<T>(this)
        }.getOrNull()
    }

    private companion object {
        val CONFIG_FLAGS = stringSetPreferencesKey(AppPreferenceKey.configFlags.name)
        val DEVICE_ID = stringPreferencesKey(AppPreferenceKey.deviceId.name)
        val DNS_FALLS_BACK = booleanPreferencesKey(AppPreferenceKey.dnsFallsBack.name)
        val EXPERIMENTAL = stringPreferencesKey(AppPreferenceKey.experimental.name)
        val EXTENSIVE_LOGGING = booleanPreferencesKey(AppPreferenceKey.extensiveLogging.name)
        val LAST_CHECKED_VERSION = stringPreferencesKey(AppPreferenceKey.lastCheckedVersion.name)
        val LAST_CHECKED_VERSION_DATE =
            longPreferencesKey(AppPreferenceKey.lastCheckedVersionDate.name)
        val LAST_USED_PROFILE_ID = stringPreferencesKey(AppPreferenceKey.lastUsedProfileId.name)
        val LOGS_PRIVATE_DATA = booleanPreferencesKey(AppPreferenceKey.logsPrivateData.name)
        val NEW_PROFILE_ENCODING = booleanPreferencesKey(AppPreferenceKey.newProfileEncoding.name)
        val RELAXED_VERIFICATION = booleanPreferencesKey(AppPreferenceKey.relaxedVerification.name)
        val SKIPS_PURCHASES = booleanPreferencesKey(AppPreferenceKey.skipsPurchases.name)
    }
}
