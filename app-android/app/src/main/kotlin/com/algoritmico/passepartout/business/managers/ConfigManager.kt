// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.managers

import com.algoritmico.passepartout.context.AppLog
import com.algoritmico.passepartout.business.extensions.JSON
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.newEventFlow
import com.algoritmico.passepartout.models.ConfigBundleConfig
import com.algoritmico.passepartout.models.ConfigEventRefresh
import com.algoritmico.passepartout.models.ConfigFlag
import com.algoritmico.passepartout.models.Event
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

interface ConfigManagerStrategy {
    suspend fun bundle(): ConfigBundle
    fun resetTTL()
}

sealed class ConfigManagerException: Exception() {
    data object RateLimit: ConfigManagerException()
}

class ConfigManager(
    private val logTag: String,
    private val strategy: ConfigManagerStrategy,
    private val buildNumber: Int = Int.MAX_VALUE
) {
    private val refreshMutex = Mutex()
    private val bundleLock = Any()
    private var bundle: ConfigBundle? = null

    private val _events = newEventFlow()
    val events: SharedFlow<Event> = _events.asSharedFlow()

    suspend fun refreshBundle(): Boolean {
        if (!refreshMutex.tryLock()) {
            return false
        }
        return runCatchingNonFatal {
            AppLog.d(logTag, "Config: refreshing bundle...")
            val newBundle = strategy.bundle()
            val event = synchronized(bundleLock) {
                bundle = newBundle
                refreshEvent(newBundle)
            }
            _events.emit(event)
            AppLog.i(logTag, "Config: active flags = ${event.flags}")
            AppLog.d(logTag, "Config: $newBundle")
            true
        }.also {
            refreshMutex.unlock()
        }.getOrElse {
            when (it) {
                is ConfigManagerException.RateLimit -> {
                    AppLog.d(logTag, "Config: TTL")
                    false
                }
                else -> {
                    AppLog.e(logTag, "Config: Unable to refresh flags", it)
                    throw it
                }
            }
        }
    }

    fun resetTTL() {
        strategy.resetTTL()
    }

    fun isActive(flag: ConfigFlag): Boolean {
        return activeConfig(flag) != null
    }

    fun data(flag: ConfigFlag): JsonElement? {
        return activeConfig(flag)?.data
    }

    val activeFlags: Set<ConfigFlag>
        get() = synchronized(bundleLock) {
            bundle?.activeFlags(buildNumber) ?: emptySet()
        }

    private fun activeConfig(flag: ConfigFlag): ConfigBundleConfig? {
        return synchronized(bundleLock) {
            bundle?.map?.get(flag)?.takeIf {
                it.isActive(buildNumber)
            }
        }
    }

    private fun refreshEvent(bundle: ConfigBundle): ConfigEventRefresh {
        val activeFlags = bundle.activeFlags(buildNumber)
            .sortedBy { it.ordinal }
        val data = activeFlags
            .mapNotNull { flag ->
                bundle.map[flag]?.data?.let { flag.value to it }
            }
            .toMap()
        return ConfigEventRefresh(
            flags = activeFlags,
            data = JsonObject(data)
        )
    }
}

class ConfigBundle(
    val map: Map<ConfigFlag, ConfigBundleConfig>
) {
    fun activeFlags(buildNumber: Int): Set<ConfigFlag> {
        return map
            .filterValues { it.isActive(buildNumber) }
            .keys
    }

    override fun toString(): String {
        return "ConfigBundle(map=$map)"
    }

    companion object {
        fun decode(data: ByteArray): ConfigBundle {
            val map = JSON
                .decode<Map<String, ConfigBundleConfig>>(data.decodeToString())
                .mapNotNull { (key, value) ->
                    ConfigFlag.decode(key)?.let { it to value }
                }
                .toMap()
            return ConfigBundle(map)
        }
    }
}

private fun ConfigBundleConfig.isActive(buildNumber: Int): Boolean {
    if (minBuild != null && buildNumber < minBuild) {
        return false
    }
    return rate == 100
}
