// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import com.algoritmico.passepartout.abi.models.ConfigEventRefresh
import com.algoritmico.passepartout.abi.models.ConfigFlag
import com.algoritmico.passepartout.abi.models.Event
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import java.io.Closeable

class ConfigObservable(
    events: Flow<Event>,
    coroutineScope: CoroutineScope
) : Closeable {
    private val scope = CoroutineScope(
        coroutineScope.coroutineContext + SupervisorJob(coroutineScope.coroutineContext[Job])
    )

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()

    init {
        events
            .onEach(::onUpdate)
            .launchIn(scope)
    }

    private fun onUpdate(event: Event) {
        if (event is ConfigEventRefresh) {
            _state.value = State(
                activeFlags = event.flags.toSet(),
                allData = event.data.configData()
            )
        }
    }

    fun isActive(flag: ConfigFlag): Boolean {
        return state.value.isActive(flag)
    }

    fun data(flag: ConfigFlag): JsonElement? {
        return state.value.data(flag)
    }

    val isUsingExperimentalFeatures: Boolean
        get() = state.value.isUsingExperimentalFeatures

    override fun close() {
        scope.cancel()
    }

    data class State(
        val activeFlags: Set<ConfigFlag> = emptySet(),
        val allData: Map<ConfigFlag, JsonElement> = emptyMap()
    ) {
        fun isActive(flag: ConfigFlag): Boolean {
            return activeFlags.contains(flag)
        }

        fun data(flag: ConfigFlag): JsonElement? {
            return allData[flag]
        }

        val isUsingExperimentalFeatures: Boolean
            get() = activeFlags.intersect(ExperimentalFeatureFlags).isNotEmpty()
    }

    private companion object {
        val ExperimentalFeatureFlags = setOf(
            ConfigFlag.ovpnV3,
            ConfigFlag.wgCrossV2
        )
    }

    private fun JsonElement.configData(): Map<ConfigFlag, JsonElement> {
        return (this as? JsonObject)
            ?.mapNotNull { (key, value) ->
                ConfigFlag.decode(key)?.let {
                    it to value
                }
            }
            ?.toMap()
            ?: emptyMap()
    }
}
