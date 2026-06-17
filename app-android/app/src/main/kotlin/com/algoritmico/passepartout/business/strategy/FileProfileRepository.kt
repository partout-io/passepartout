// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.business.strategy

import android.util.Log
import com.algoritmico.passepartout.business.extensions.JSON
import com.algoritmico.passepartout.business.managers.ProfileManagerException
import com.algoritmico.passepartout.business.managers.ProfileRepository
import io.partout.models.TaggedProfile
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.jsonPrimitive
import java.io.File
import java.util.UUID

class FileProfileRepository(
    private val logTag: String,
    directory: File
) : ProfileRepository {
    private val rootDirectory = directory
    private val objectsDirectory = File(rootDirectory, "objects")
    private val tmpDirectory = File(rootDirectory, "tmp")
    private val indexFile = File(rootDirectory, "index.json")

    init {
        rootDirectory.mkdirs()
        objectsDirectory.mkdirs()
        tmpDirectory.mkdirs()
        ensureIndex()
    }

    override suspend fun fetchProfiles(): Collection<TaggedProfile> = withContext(Dispatchers.IO) {
        loadProfiles()
    }

    override suspend fun saveProfile(profile: TaggedProfile) = withContext(Dispatchers.IO) {
        val data = JSON.encode(profile).encodeToByteArray()
        writeAtomically(data, objectFile(profile.id))
        persistIndex(loadProfilesById())
    }

    override suspend fun removeProfiles(profileIds: Collection<String>) = withContext(Dispatchers.IO) {
        if (profileIds.isEmpty()) {
            return@withContext
        }
        profileIds.forEach { profileId ->
            objectFile(profileId).takeIf { it.exists() }?.delete()
        }
        persistIndex(loadProfilesById())
    }

    private fun ensureIndex() {
        if (!indexFile.exists()) {
            persistIndex(loadProfilesByIdFromObjects())
            return
        }
        runCatching {
            loadIndex()
        }.onFailure {
            Log.e(logTag, "Rebuilding malformed profile index", it)
            persistIndex(loadProfilesByIdFromObjects())
        }
    }

    private fun loadProfiles(): List<TaggedProfile> {
        val profilesById = loadProfilesById()
        return orderedIds().mapNotNull { profileId ->
            profilesById[profileId] ?: throw ProfileManagerException.NotFound(profileId)
        }
    }

    private fun loadProfilesById(): Map<String, TaggedProfile> {
        val knownIds = orderedIds().toSet()
        val objects = loadProfilesByIdFromObjects()
        val unknownIds = objects.keys - knownIds
        if (unknownIds.isNotEmpty()) {
            Log.e(logTag, "Profile index missing ${unknownIds.size} entries, rebuilding")
            persistIndex(objects)
        }
        return objects
    }

    private fun loadProfilesByIdFromObjects(): Map<String, TaggedProfile> {
        return objectsDirectory
            .listFiles { file -> file.isFile && file.extension == "json" }
            .orEmpty()
            .associate { file ->
                val profile = runCatching {
                    JSON.decode<TaggedProfile>(file.readText())
                }.getOrElse {
                    throw ProfileManagerException.Generic(
                        "Unable to decode profile at ${file.name}",
                        it
                    )
                }
                profile.id to profile
            }
    }

    private fun orderedIds(): List<String> {
        return loadIndex().profiles.map { it.id }
    }

    private fun loadIndex(): IndexFile {
        return runCatching {
            JSON.decode<IndexFile>(indexFile.readText())
        }.getOrElse {
            throw ProfileManagerException.Generic("Unable to decode profile index", it)
        }
    }

    private fun persistIndex(profilesById: Map<String, TaggedProfile>) {
        val entries = profilesById.values
            .sortedWith(profileComparator)
            .map { profile ->
                IndexEntry(
                    id = profile.id,
                    name = profile.name,
                    lastUpdate = profile.lastUpdate,
                    fingerprint = profile.fingerprint
                )
            }
        val index = IndexFile(
            version = 1,
            profiles = entries
        )
        writeAtomically(
            JSON.encode(index).encodeToByteArray(),
            indexFile
        )
    }

    private fun objectFile(profileId: String): File {
        return File(objectsDirectory, "$profileId.json")
    }

    private fun writeAtomically(data: ByteArray, destination: File) {
        val temporaryFile = File(tmpDirectory, "${UUID.randomUUID()}.tmp")
        temporaryFile.writeBytes(data)
        if (destination.exists() && !destination.delete()) {
            temporaryFile.delete()
            throw ProfileManagerException.Generic("Unable to replace ${destination.name}")
        }
        if (!temporaryFile.renameTo(destination)) {
            temporaryFile.delete()
            throw ProfileManagerException.Generic("Unable to move ${temporaryFile.name} to ${destination.name}")
        }
    }

    @Serializable
    private data class IndexFile(
        val version: Int,
        val profiles: List<IndexEntry>
    )

    @Serializable
    private data class IndexEntry(
        val id: String,
        val name: String,
        val lastUpdate: JsonElement? = null,
        val fingerprint: String? = null
    )

    private companion object {
        val profileComparator = compareBy<TaggedProfile> {
            it.name.lowercase()
        }.thenByDescending {
            it.lastUpdate?.jsonPrimitive?.doubleOrNull ?: Double.NEGATIVE_INFINITY
        }.thenBy {
            it.id
        }

        val TaggedProfile.lastUpdate: JsonElement?
            get() = userInfo?.jsonObjectOrNull?.get("lastUpdate")

        val TaggedProfile.fingerprint: String?
            get() = userInfo
                ?.jsonObjectOrNull
                ?.get("fingerprint")
                ?.jsonPrimitive
                ?.content

        val JsonElement.jsonObjectOrNull: JsonObject?
            get() = this as? JsonObject
    }
}
