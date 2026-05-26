// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.content.Context
import android.util.Log
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.MutablePreferences
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.algoritmico.passepartout.Globals
import com.algoritmico.passepartout.abi.AppABIKeyStoreProtocol
import com.algoritmico.passepartout.abi.default
import com.algoritmico.passepartout.abi.models.AppPreferenceKey
import com.algoritmico.passepartout.abi.models.AppPreferences
import com.algoritmico.passepartout.abi.models.ConfigFlag
import com.algoritmico.passepartout.abi.models.Event
import com.algoritmico.passepartout.abi.models.MixedEventShouldUpdatePreferences
import com.algoritmico.passepartout.abi.update
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.runBlocking
import java.io.Closeable

class UserPreferencesObservable(
    private val logTag: String,
    private val abi: AppABIKeyStoreProtocol,
    events: Flow<Event>,
    coroutineScope: CoroutineScope,
    private val context: Context,
    filename: String
) : Closeable {
    private val scope = CoroutineScope(
        coroutineScope.coroutineContext + SupervisorJob(coroutineScope.coroutineContext[Job])
    )

    private val Context.store: DataStore<Preferences> by preferencesDataStore(filename)
    val flow: Flow<Preferences>
        get() {
            return context.store.data
        }

    private val preferences: Flow<AppPreferences> = flow.map { it.toAppPreferences() }
    private var snapshot = flow.loadPreferences()

    init {
        events
            .onEach(::onUpdate)
            .launchIn(scope)
    }

    override fun close() {
        scope.cancel()
    }

    val dnsFallback: Flow<Boolean> = preferences.map { it.dnsFallsBack }

    suspend fun toggleDnsFallback() {
        context.store.edit {
            val newValue = !(it[DNS_FALLS_BACK] ?: AppPreferences.default.dnsFallsBack)
            it[DNS_FALLS_BACK] = newValue
            snapshot = snapshot.copy(dnsFallsBack = newValue)
        }
        savePreferences()
    }

    fun preferencesJSON(): String? {
        return runCatching {
            return Globals.json.encodeToString(snapshot)
        }.getOrNull()
    }

    private suspend fun onUpdate(event: Event) {
        if (event !is MixedEventShouldUpdatePreferences) return
        Log.d(logTag, "Updating fields from library: ${event.fields}")
        context.store.edit {
            it.update(event.preferences, event.fields)
        }
        snapshot = snapshot.update(event.preferences, event.fields)
        savePreferences()
    }

    private fun savePreferences() {
        Log.d(logTag, "Saving new preferences: $snapshot")
        abi.set(snapshot)
    }

    fun Flow<Preferences>.loadPreferences(): AppPreferences {
        return runBlocking {
            first().toAppPreferences()
        }
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
                    this[EXPERIMENTAL] = Globals.json.encodeToString(new.experimental)
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
        } else {
            this[key] = value
        }
    }

    private inline fun <reified T> String.decodePreference(): T? {
        return runCatching {
            Globals.json.decodeFromString<T>(this)
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
