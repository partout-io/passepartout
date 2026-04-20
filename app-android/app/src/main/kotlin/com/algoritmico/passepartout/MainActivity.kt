// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.lifecycleScope
import com.algoritmico.passepartout.abi.AppConstants
import com.algoritmico.passepartout.abi.AppProfileHeader
import com.algoritmico.passepartout.abi.Event
import com.algoritmico.passepartout.abi.ProfileEventRefresh
import com.algoritmico.passepartout.abi.ProfileEventSave
import com.algoritmico.passepartout.helpers.ABIEventCallback
import com.algoritmico.passepartout.helpers.NativeLibraryWrapper
import io.partout.abi.TaggedProfile
import io.partout.jni.AndroidTunnelStrategy
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.io.File

val globalJsonCoder = Json {
    ignoreUnknownKeys = true
}

class MainActivity : ComponentActivity(), ABIEventCallback {
    private val wrapper = NativeLibraryWrapper()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var headers = mutableStateOf<Map<String, AppProfileHeader>>(emptyMap())
    private lateinit var tunnelStrategy: AndroidTunnelStrategy

    override fun onEvent(eventCtx: Any?, eventJSON: String) {
        mainHandler.post {
            val event: Event = globalJsonCoder.decodeFromString(eventJSON)
            Log.i("Passepartout", ">>> MainActivity: $event")
            when (event) {
                is ProfileEventRefresh -> {
                    headers.value = event.headers
                }

                is ProfileEventSave -> {
                    Log.i("Passepartout", ">>> MainActivity: profile = ${event.profile}")
                }

                else -> {
                    // Other events
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Start easy, test Partout version
        val version = wrapper.partoutVersion()
        Log.e("Passepartout", ">>> $version")

        // Initialize app and event callback
        val bundle = String(assets.open("bundle.json").readBytes())
        val constants = String(assets.open("constants.json").readBytes())
        val profilesDir = File(noBackupFilesDir, "profiles-v1").apply {
            mkdirs()
        }.absolutePath
        val cachePath = cacheDir.absolutePath
        val eventHandler = this
        wrapper.appInit(
            bundle,
            constants,
            profilesDir,
            cachePath,
            this,
            eventHandler
        )
        tunnelStrategy = AndroidTunnelStrategy(
            context = this,
            vpnServiceClass = PassepartoutVPNService::class.java,
            requestVpnPermission = vpnPermissionLauncher::launch
        )

        val constantsJSON: AppConstants = globalJsonCoder.decodeFromString(constants)
        Log.e("Passepartout", ">>> Test GitHub constants: ${constantsJSON.github.discussionsURL}")

        setContent {
            HelloWorldView(
                version,
                headers,
                { startVpnService() },
                { stopVpnService() },
                { importProfile() }
            )
        }
    }

    override fun onStart() {
        super.onStart()
        wrapper.appOnForeground()
    }

    fun startVpnService() {
        lifecycleScope.launch {
            val profile = runCatching {
                loadFirstStoredProfile()
            }.onFailure {
                Log.e("Passepartout", "Unable to load first stored profile", it)
            }.getOrNull()
            if (profile == null) {
                Log.e("Passepartout", "No profiles found in profiles-v1")
                return@launch
            }
            tunnelStrategy.connect(profile)
        }
    }

    fun stopVpnService() {
        lifecycleScope.launch {
            tunnelStrategy.disconnect()
        }
    }

    fun importProfile(connect: Boolean = false) {
        val file = String(assets.open("vps.conf").readBytes())
//        val file = String(assets.open("vps-crypt-v2.ovpn").readBytes())
        wrapper.appImportProfileText(file, "SomeName") { ctx, code, errorMessage ->
            if (code == 0) {
                Log.i("Passepartout", "Import success!")
            } else {
                Log.e("Passepartout", "Import failure (code=$code): $errorMessage")
            }
        }
    }

    private val vpnPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        tunnelStrategy.onVpnPermissionResult(result.resultCode == RESULT_OK)
    }

    private suspend fun loadFirstStoredProfile(): TaggedProfile? = withContext(Dispatchers.IO) {
        val profilesDir = File(noBackupFilesDir, PROFILES_DIR)
        val firstProfileId = readFirstProfileId(profilesDir) ?: return@withContext null
        val profileFile = File(File(profilesDir, OBJECTS_DIR), "$firstProfileId.json")
        if (!profileFile.isFile) {
            Log.e("Passepartout", "Stored profile object does not exist: ${profileFile.absolutePath}")
            return@withContext null
        }
        globalJsonCoder.decodeFromString<TaggedProfile>(profileFile.readText())
    }

    private fun readFirstProfileId(profilesDir: File): String? {
        val indexFile = File(profilesDir, INDEX_FILE)
        if (!indexFile.isFile) {
            Log.e("Passepartout", "Profile index does not exist: ${indexFile.absolutePath}")
            return null
        }
        val index = globalJsonCoder.decodeFromString<ProfileIndex>(indexFile.readText())
        return index.profiles.firstOrNull()?.id
    }

    @Serializable
    private data class ProfileIndex(
        @SerialName("profiles")
        val profiles: List<ProfileIndexEntry> = emptyList()
    )

    @Serializable
    private data class ProfileIndexEntry(
        @SerialName("id")
        val id: String
    )

    private companion object {
        const val PROFILES_DIR = "profiles-v1"
        const val OBJECTS_DIR = "objects"
        const val INDEX_FILE = "index.json"
    }
}
