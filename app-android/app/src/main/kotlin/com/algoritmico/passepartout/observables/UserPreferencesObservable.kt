// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.util.Log
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.MutablePreferences
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import com.algoritmico.passepartout.business.extensions.default
import com.algoritmico.passepartout.business.extensions.throwIfCancellation
import com.algoritmico.passepartout.business.extensions.toAppPreferences
import com.algoritmico.passepartout.business.extensions.toggleDnsFallback
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
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
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

    private val flow: Flow<Preferences>
        get() {
            return store.data.catch {
                it.throwIfCancellation()
                Log.e(logTag, "Unable to read preferences", it)
                emit(emptyPreferences())
            }
        }

    val preferences: Flow<AppPreferences> = flow.map { it.toAppPreferences() }
    val currentPreferences: AppPreferences
        get() = snapshot
    private var snapshot: AppPreferences
    //endregion

    //region Lifecycle
    init {
        snapshot = runCatching {
            runBlocking {
                preferences.first()
            }
        }.getOrElse {
            if (it !is Exception) {
                throw it
            }
            Log.e(logTag, "Unable to load preferences", it)
            AppPreferences.default
        }
    }

    override fun close() {
        scope.cancel()
    }
    //endregion

    //region Editing
    val dnsFallback: Flow<Boolean> = preferences.map { it.dnsFallsBack }

    suspend fun toggleDnsFallback() {
        editSafely {
            val newValue = it.toggleDnsFallback()
            snapshot = snapshot.copy(dnsFallsBack = newValue)
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
        runCatching {
            store.edit(transform)
            savePreferences()
        }.onFailure {
            Log.e(logTag, "Unable to save preferences", it)
            throw it
        }
    }

    private fun savePreferences() {
        Log.d(logTag, "Preferences updated: $snapshot")
    }
    //endregion
}
