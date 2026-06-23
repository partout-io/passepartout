// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import com.algoritmico.passepartout.context.AppLog
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.MutablePreferences
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import com.algoritmico.passepartout.business.extensions.appPreferences
import com.algoritmico.passepartout.business.extensions.default
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.extensions.update
import com.algoritmico.passepartout.business.extensions.updateExperimentalPreferences
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.models.ExperimentalPreferences
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import java.io.Closeable

class UserPreferencesObservable(
    private val logTag: String,
    coroutineScope: CoroutineScope,
    private val store: DataStore<Preferences>
) : Closeable {
    //region State
    private val scope = CoroutineScope(
        coroutineScope.coroutineContext + SupervisorJob(coroutineScope.coroutineContext[Job])
    )

    val preferences: Flow<AppPreferences> = store.appPreferences(logTag)
    val currentPreferences: AppPreferences
        get() = snapshot
    private var snapshot: AppPreferences
    //endregion

    //region Lifecycle
    init {
        snapshot = runCatchingNonFatal {
            runBlocking {
                preferences.first()
            }
        }.getOrElse {
            AppLog.w(logTag, "Unable to load preferences", it)
            AppPreferences.default
        }
    }

    override fun close() {
        scope.cancel()
    }
    //endregion

    //region Editing
    suspend fun updateDnsFallback(isEnabled: Boolean) {
        updatePreferences(
            fields = listOf(AppPreferenceKey.dnsFallsBack)
        ) {
            it.copy(dnsFallsBack = isEnabled)
        }
    }

    suspend fun updateExperimentalPreferences(
        transform: (ExperimentalPreferences) -> ExperimentalPreferences
    ) {
        editSafely {
            val newValue = it.updateExperimentalPreferences(snapshot.experimental, transform)
            snapshot = snapshot.copy(experimental = newValue)
        }
    }

    suspend fun updatePreferences(
        fields: List<AppPreferenceKey>,
        transform: (AppPreferences) -> AppPreferences
    ) {
        editSafely {
            val newValue = transform(snapshot)
            it.update(fields, newValue)
            snapshot = snapshot.update(fields, newValue)
        }
    }
    //endregion

    //region Private
    private suspend fun editSafely(transform: suspend (MutablePreferences) -> Unit) {
        runCatchingNonFatal {
            store.edit(transform)
            savePreferences()
        }.onFailure {
            AppLog.e(logTag, "Unable to save preferences", it)
            throw it
        }
    }

    private fun savePreferences() {
        AppLog.d(logTag, "Preferences updated: $snapshot")
    }
    //endregion
}
