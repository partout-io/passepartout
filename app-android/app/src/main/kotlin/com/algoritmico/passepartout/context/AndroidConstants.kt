// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.context

data class AndroidConstants(
    val assets: Assets = Assets(),
    val diagnostics: Diagnostics = Diagnostics(),
    val events: Events = Events(),
    val profileImport: ProfileImport = ProfileImport(),
    val storage: Storage = Storage(),
    val tags: Tags = Tags(),
    val tunnel: Tunnel = Tunnel()
) {
    data class Assets(
        val constantsFilename: String = "constants.json",
        val creditsFilename: String = "credits.json"
    )

    data class Diagnostics(
        val logcatTimeoutSeconds: Int = 3,
        val logcatViewHours: Long = 6L,
        val logcatLevel: String = "I",
        val logcatDestroyTimeoutMillis: Long = 500L,
        val exitReasonsFilename: String = "exit-reasons.txt",
        val exitReasonsLimit: Int = 8,
        val issueCacheDirectory: String = "issue",
        val issueEmailMimeType: String = "message/rfc822"
    ) {
        val logcatTimeoutMillis: Long
            get() = (logcatTimeoutSeconds * 1000.0)
                .toLong()
                .coerceAtLeast(1L)
    }

    data class Events(
        val bufferCapacity: Int = 64,
        val replay: Int = 64
    )

    data class Tags(
        val app: String = "Passepartout",
        val appPartout: String = "PartoutApp",
        val service: String = "PassepartoutVpnService",
        val servicePartout: String = "PartoutService",
        val partoutJni: String = "PartoutJNI",
        val outOfBand: String = "PassepartoutOOB"
    ) {
        val appTags: Collection<String>
            get() = listOf(app, appPartout)

        val serviceTags: Collection<String>
            get() = listOf(service, servicePartout, partoutJni)
    }

    data class ProfileImport(
        val mimeTypes: List<String> = listOf(
            "application/x-openvpn-profile",
            "application/x-wireguard-profile",
            "application/octet-stream",
            "text/*",
            "*/*"
        )
    )

    data class Storage(
        val tunnelProfileFilename: String = "tunnel_profile.json",
        val tunnelPreferencesFilename: String = "tunnel_preferences.json",
        val preferencesStoreName: String = "preferences"
    )

    data class Tunnel(
        val logsSnapshots: Boolean = false,
        val isForeground: Boolean = true
    )
}

val defaultAndroidConstants = AndroidConstants()
