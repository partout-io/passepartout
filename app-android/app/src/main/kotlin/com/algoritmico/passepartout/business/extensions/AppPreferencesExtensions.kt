// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.extensions

import android.util.Log
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.MutablePreferences
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.models.ConfigFlag
import com.algoritmico.passepartout.models.ExperimentalPreferences
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map

data class LastCheckedVersionSnapshot(
    val timestamp: Long,
    val version: String?
)

//region Flows
fun DataStore<Preferences>.appPreferences(logTag: String): Flow<AppPreferences> {
    return data.safePreferences(logTag)
        .map { it.toAppPreferences() }
}

fun Flow<Preferences>.appPreferences(logTag: String): Flow<AppPreferences> {
    return safePreferences(logTag)
        .map { it.toAppPreferences() }
}

fun DataStore<Preferences>.lastCheckedVersionSnapshots(
    logTag: String
): Flow<LastCheckedVersionSnapshot?> {
    return appPreferences(logTag)
        .map { it.lastCheckedVersionSnapshot() }
}

private fun Flow<Preferences>.safePreferences(logTag: String): Flow<Preferences> {
    return catch {
        it.throwIfFatal()
        Log.e(logTag, "Unable to read preferences", it)
        emit(emptyPreferences())
    }
}
//endregion

//region Mapping
val AppPreferences.Companion.default: AppPreferences
    get() = AppPreferences(
        configFlags = listOf(),
        dnsFallsBack = true,
        experimental = ExperimentalPreferences(listOf(), listOf()),
        extensiveLogging = false,
        logsPrivateData = false,
        newProfileEncoding = false,
        relaxedVerification = false,
        skipsPurchases = false
    )

fun AppPreferences.update(fields: Collection<AppPreferenceKey>, new: AppPreferences): AppPreferences {
    var updated = this
    fields.forEach {
        updated = when (it) {
            AppPreferenceKey.deviceId -> updated.copy(
                deviceId = new.deviceId
            )
            AppPreferenceKey.configFlags -> updated.copy(
                configFlags = new.configFlags
            )
            AppPreferenceKey.dnsFallsBack -> updated.copy(
                dnsFallsBack = new.dnsFallsBack
            )
            AppPreferenceKey.experimental -> updated.copy(
                experimental = new.experimental
            )
            AppPreferenceKey.extensiveLogging -> updated.copy(
                extensiveLogging = new.extensiveLogging
            )
            AppPreferenceKey.lastCheckedVersion -> updated.copy(
                lastCheckedVersion = new.lastCheckedVersion
            )
            AppPreferenceKey.lastCheckedVersionDate -> updated.copy(
                lastCheckedVersionTimestamp = new.lastCheckedVersionTimestamp
            )
            AppPreferenceKey.lastUsedProfileId -> updated.copy(
                lastUsedProfileUUID = new.lastUsedProfileUUID
            )
            AppPreferenceKey.logsPrivateData -> updated.copy(
                logsPrivateData = new.logsPrivateData
            )
            AppPreferenceKey.newProfileEncoding -> updated.copy(
                newProfileEncoding = new.newProfileEncoding
            )
            AppPreferenceKey.relaxedVerification -> updated.copy(
                relaxedVerification = new.relaxedVerification
            )
            AppPreferenceKey.skipsPurchases -> updated.copy(
                skipsPurchases = new.skipsPurchases
            )
        }
    }
    return updated
}

fun Preferences.toAppPreferences(): AppPreferences {
    val default = AppPreferences.default
    return AppPreferences(
        configFlags = this[K.CONFIG_FLAGS]
            ?.mapNotNull { ConfigFlag.decode(it) }
            ?.toMutableList()
            ?: default.configFlags,
        dnsFallsBack = this[K.DNS_FALLS_BACK]
            ?: default.dnsFallsBack,
        experimental = this[K.EXPERIMENTAL]
            ?.decodePreference()
            ?: default.experimental,
        extensiveLogging = this[K.EXTENSIVE_LOGGING]
            ?: default.extensiveLogging,
        logsPrivateData = this[K.LOGS_PRIVATE_DATA]
            ?: default.logsPrivateData,
        newProfileEncoding = this[K.NEW_PROFILE_ENCODING]
            ?: default.newProfileEncoding,
        relaxedVerification = this[K.RELAXED_VERIFICATION]
            ?: default.relaxedVerification,
        skipsPurchases = this[K.SKIPS_PURCHASES]
            ?: default.skipsPurchases,
        deviceId = this[K.DEVICE_ID],
        lastCheckedVersionTimestamp = this[K.LAST_CHECKED_VERSION_DATE],
        lastCheckedVersion = this[K.LAST_CHECKED_VERSION],
        lastUsedProfileUUID = this[K.LAST_USED_PROFILE_ID]
    )
}

private fun AppPreferences.lastCheckedVersionSnapshot(): LastCheckedVersionSnapshot? {
    val timestamp = lastCheckedVersionTimestamp ?: return null
    return LastCheckedVersionSnapshot(timestamp, lastCheckedVersion)
}

private inline fun <reified T> String.decodePreference(): T? {
    return runCatching {
        JSON.decode<T>(this)
    }.getOrNull()
}
//endregion

//region Store
fun MutablePreferences.toggleDnsFallback(): Boolean {
    val newValue = !(this[K.DNS_FALLS_BACK] ?: AppPreferences.default.dnsFallsBack)
    this[K.DNS_FALLS_BACK] = newValue
    return newValue
}

suspend fun DataStore<Preferences>.updateLastCheckedVersion(
    timestamp: Long,
    version: String?
) {
    edit {
        val current = it.toAppPreferences()
        val newValue = current.copy(
            lastCheckedVersionTimestamp = timestamp,
            lastCheckedVersion = version ?: current.lastCheckedVersion
        )
        it.update(LAST_CHECKED_VERSION_FIELDS, newValue)
    }
}

fun MutablePreferences.updateExperimentalPreferences(
    current: ExperimentalPreferences,
    transform: (ExperimentalPreferences) -> ExperimentalPreferences
): ExperimentalPreferences {
    val newValue = transform(
        this[K.EXPERIMENTAL]?.decodePreference<ExperimentalPreferences>()
            ?: current
    )
    this[K.EXPERIMENTAL] = JSON.encode(newValue)
    return newValue
}

fun MutablePreferences.update(fields: Collection<AppPreferenceKey>, new: AppPreferences) {
    fields.forEach {
        when (it) {
            AppPreferenceKey.deviceId ->
                setOrRemove(
                    K.DEVICE_ID,
                    new.deviceId
                )

            AppPreferenceKey.configFlags ->
                this[K.CONFIG_FLAGS] = new.configFlags.map {
                    flags -> flags.value
                }.toSet()

            AppPreferenceKey.dnsFallsBack ->
                this[K.DNS_FALLS_BACK] = new.dnsFallsBack

            AppPreferenceKey.experimental ->
                this[K.EXPERIMENTAL] = JSON.encode(new.experimental)

            AppPreferenceKey.extensiveLogging ->
                this[K.EXTENSIVE_LOGGING] = new.extensiveLogging

            AppPreferenceKey.lastCheckedVersion ->
                setOrRemove(
                    K.LAST_CHECKED_VERSION,
                    new.lastCheckedVersion
                )

            AppPreferenceKey.lastCheckedVersionDate ->
                setOrRemove(
                    K.LAST_CHECKED_VERSION_DATE,
                    new.lastCheckedVersionTimestamp
                )

            AppPreferenceKey.lastUsedProfileId ->
                setOrRemove(
                    K.LAST_USED_PROFILE_ID,
                    new.lastUsedProfileUUID
                )

            AppPreferenceKey.logsPrivateData ->
                this[K.LOGS_PRIVATE_DATA] = new.logsPrivateData

            AppPreferenceKey.newProfileEncoding ->
                this[K.NEW_PROFILE_ENCODING] = new.newProfileEncoding

            AppPreferenceKey.relaxedVerification ->
                this[K.RELAXED_VERIFICATION] = new.relaxedVerification

            AppPreferenceKey.skipsPurchases ->
                this[K.SKIPS_PURCHASES] = new.skipsPurchases
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

private object K {
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

private val LAST_CHECKED_VERSION_FIELDS = listOf(
    AppPreferenceKey.lastCheckedVersion,
    AppPreferenceKey.lastCheckedVersionDate
)
//endregion

//region Experimental
fun AppPreferences.isFlagEnabled(flag: ConfigFlag): Boolean {
    return (configFlags.contains(flag) || experimental.enabledConfigFlags.contains(flag)) &&
            !experimental.ignoredConfigFlags.contains(flag)
}

fun ExperimentalPreferences.isAllowed(flag: ConfigFlag): Boolean {
    return !ignoredConfigFlags.contains(flag)
}

fun ExperimentalPreferences.setAllowed(
    flag: ConfigFlag,
    isAllowed: Boolean
): ExperimentalPreferences {
    return if (isAllowed) {
        unignore(flag)
    } else {
        ignore(flag)
    }
}

fun ExperimentalPreferences.ignore(flag: ConfigFlag): ExperimentalPreferences {
    return copy(
        ignoredConfigFlags = ignoredConfigFlags.adding(flag)
    )
}

fun ExperimentalPreferences.unignore(flag: ConfigFlag): ExperimentalPreferences {
    return copy(
        ignoredConfigFlags = ignoredConfigFlags.removing(flag)
    )
}

fun ExperimentalPreferences.enable(flag: ConfigFlag): ExperimentalPreferences {
    return copy(
        enabledConfigFlags = enabledConfigFlags.adding(flag)
    )
}

fun ExperimentalPreferences.disable(flag: ConfigFlag): ExperimentalPreferences {
    return copy(
        enabledConfigFlags = enabledConfigFlags.removing(flag)
    )
}

private fun List<ConfigFlag>.adding(flag: ConfigFlag): List<ConfigFlag> {
    return if (contains(flag)) {
        this
    } else {
        this + flag
    }
}

private fun List<ConfigFlag>.removing(flag: ConfigFlag): List<ConfigFlag> {
    return filterNot { it == flag }
}
//endregion
