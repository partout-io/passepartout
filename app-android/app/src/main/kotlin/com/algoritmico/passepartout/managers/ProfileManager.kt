// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.managers

import android.util.Log
import com.algoritmico.passepartout.PassepartoutWrapper
import com.algoritmico.passepartout.extensions.fingerprint
import com.algoritmico.passepartout.injection.JSON
import com.algoritmico.passepartout.injection.newEventFlow
import com.algoritmico.passepartout.models.AppProfileHeader
import com.algoritmico.passepartout.models.Event
import com.algoritmico.passepartout.models.ProfileEventDelete
import com.algoritmico.passepartout.models.ProfileEventLocalProfiles
import com.algoritmico.passepartout.models.ProfileEventReady
import com.algoritmico.passepartout.models.ProfileEventRefresh
import com.algoritmico.passepartout.models.ProfileEventSave
import io.partout.abi.PartoutResult
import io.partout.extensions.moduleId
import io.partout.extensions.moduleType
import io.partout.models.ModuleType
import io.partout.models.TaggedProfile
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

interface ProfileRepository {
    suspend fun fetchProfiles(): Collection<TaggedProfile>
    suspend fun saveProfile(profile: TaggedProfile)
    suspend fun removeProfiles(profileIds: Collection<String>)
}

class ProfileManager(
    private val logTag: String,
    private val library: PassepartoutWrapper,
    private val repository: ProfileRepository,
) {
    private var profiles: Map<String, TaggedProfile> = emptyMap()

    private val _events = newEventFlow()
    val events: SharedFlow<Event> = _events.asSharedFlow()

    suspend fun loadInitialProfiles() {
        runCatching {
            setProfiles(repository.fetchProfiles())
        }.onFailure {
            Log.e(logTag, "Unable to load initial profiles", it)
        }
        _events.emit(ProfileEventReady())
    }

    suspend fun importText(text: String, name: String?) {
        val result = PartoutResult.await { completion ->
            library.partoutImportProfile(text, name, completion)
        }
        result.payload?.let {
            val profile = JSON.decode<TaggedProfile>(it)
            val previous = profiles[profile.id]
            repository.saveProfile(profile)
            profiles = profiles + (profile.id to profile)
            _events.emit(
                ProfileEventSave(
                    profile = profile,
                    previous = previous
                )
            )
            publishProfiles()
        }
    }

    suspend fun remove(profileId: String) {
        remove(listOf(profileId))
    }

    suspend fun remove(profileIds: Collection<String>) {
        if (profileIds.isEmpty()) {
            return
        }
        repository.removeProfiles(profileIds)
        profiles = profiles - profileIds.toSet()
        _events.emit(ProfileEventDelete(profileIds.toList()))
        publishProfiles()
    }

    fun profile(profileId: String): TaggedProfile? {
        return profiles[profileId]
    }

    private suspend fun setProfiles(newProfiles: Collection<TaggedProfile>) {
        profiles = newProfiles.associateBy { it.id }
        publishProfiles()
    }

    private suspend fun publishProfiles() {
        val newHeaders = profiles.mapValues { it.value.appHeader() }
        Log.d(logTag, "New headers: $newHeaders")
        _events.emit(ProfileEventLocalProfiles())
        _events.emit(
            ProfileEventRefresh(
                headers = newHeaders
            )
        )
    }
}

private fun TaggedProfile.appHeader(): AppProfileHeader {
    val typedModules = modules.mapNotNull { module ->
        module.moduleType?.let { type ->
            TypedModule(
                id = module.moduleId,
                type = type
            )
        }
    }
    val activeModules = activeModulesIds.mapNotNull { moduleId ->
        typedModules.firstOrNull { it.id == moduleId }
    }
    val primaryType = activeModules.firstOrNull()?.type ?: typedModules.firstOrNull()?.type
    val secondaryTypes = typedModules
        .filterNot { it.type == primaryType }
        .map { it.type }

    return AppProfileHeader(
        id = id,
        name = name,
        moduleTypes = typedModules.map { it.type },
        primaryModuleType = primaryType,
        secondaryModuleTypes = secondaryTypes,
        providerInfo = null,
        fingerprint = fingerprint ?: id,
        sharingFlags = emptyList(),
        requiredFeatures = emptyList()
    )
}

private data class TypedModule(
    val id: String?,
    val type: ModuleType
)
