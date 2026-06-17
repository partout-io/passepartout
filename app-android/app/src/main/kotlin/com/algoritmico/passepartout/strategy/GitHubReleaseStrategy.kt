// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.strategy

import android.util.Log
import com.algoritmico.passepartout.extensions.JSON
import com.algoritmico.passepartout.managers.VersionCheckerException
import com.algoritmico.passepartout.managers.VersionCheckerStrategy
import com.algoritmico.passepartout.managers.toSemanticVersionOrNull
import com.algoritmico.passepartout.models.AppPreferenceKey
import com.algoritmico.passepartout.models.AppPreferences
import com.algoritmico.passepartout.models.ChangelogEntry
import com.algoritmico.passepartout.models.SemanticVersion
import com.algoritmico.passepartout.observables.UserPreferencesObservable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

class GitHubReleaseStrategy(
    private val logTag: String,
    private val releaseURL: String,
    private val changelogURL: (String) -> String,
    private val rateLimit: Double,
    private val fetcher: suspend (String) -> ByteArray,
    private val userPreferencesObservable: UserPreferencesObservable
) : VersionCheckerStrategy {
    override suspend fun latestVersion(sinceTimestamp: Long?): SemanticVersion {
        if (sinceTimestamp != null) {
            val elapsed = (System.currentTimeMillis() - sinceTimestamp) / 1000.0
            if (elapsed < rateLimit) {
                Log.d(logTag, "Version (GitHub): elapsed $elapsed < $rateLimit")
                throw VersionCheckerException.RateLimit
            }
        }
        val data = fetcher(releaseURL)
        val json = JSON.decode<VersionJSON>(data.decodeToString())
        val newVersion = json.name
        val semanticVersion = newVersion.toSemanticVersionOrNull()
        if (semanticVersion == null) {
            Log.e(logTag, "Version (GitHub): unparsable release name '$newVersion'")
            throw VersionCheckerException.UnexpectedResponse
        }
        return semanticVersion
    }

    override suspend fun fetchChangelog(version: String): List<ChangelogEntry> {
        val url = changelogURL(version)
        val text = fetcher(url).decodeToString()
        return text.split("\n")
            .filter { it.isNotEmpty() }
            .mapIndexedNotNull { index, line ->
                line.toChangelogEntry(index)
            }
    }

    override fun preferences(): AppPreferences {
        return userPreferencesObservable.currentPreferences
    }

    override suspend fun updatePreferences(transform: (AppPreferences) -> AppPreferences) {
        val fields = listOf(
            AppPreferenceKey.lastCheckedVersion,
            AppPreferenceKey.lastCheckedVersionDate
        )
        userPreferencesObservable.updatePreferences(fields, transform)
    }
}

private fun String.toChangelogEntry(id: Int): ChangelogEntry? {
    val entryPrefix = "* "
    if (!startsWith(entryPrefix)) {
        return null
    }

    val components = removePrefix(entryPrefix)
        .split(" ")
        .toMutableList()

    var issue: Int? = null
    val last = components.lastOrNull()
    if (components.size >= 2 && last != null && last.startsWith("(#") && last.endsWith(")")) {
        val issueString = last.substring(2, last.length - 1)
        val parsedIssue = issueString.toIntOrNull()
        if (parsedIssue != null) {
            components.removeAt(components.lastIndex)
            issue = parsedIssue
        }
    }

    return ChangelogEntry(
        id = id,
        comment = components.joinToString(" "),
        issue = issue
    )
}

@Serializable
private data class VersionJSON(
    @SerialName("name")
    val name: String,

    @SerialName("tag_name")
    val tagName: String? = null
)
