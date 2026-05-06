// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import com.algoritmico.passepartout.abi.AppProfileStatus
import com.algoritmico.passepartout.abi.AppTunnelInfo
import com.algoritmico.passepartout.abi.Event
import com.algoritmico.passepartout.abi.OnConnectionStatus
import com.algoritmico.passepartout.abi.TunnelEventRefresh
import com.algoritmico.passepartout.helpers.ABIEventDispatcher
import com.algoritmico.passepartout.helpers.ABIConnectionStatusDispatcher
import com.algoritmico.passepartout.helpers.NativeLibraryWrapper
import com.algoritmico.passepartout.helpers.globalJsonCoder
import com.algoritmico.passepartout.ui.PassepartoutApp
import io.partout.abi.ConnectionStatus
import io.partout.abi.TaggedProfile
import io.partout.jni.AndroidTunnelStrategy
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow
import java.io.Closeable
import java.io.File

class MainActivity : ComponentActivity() {
    private val library = NativeLibraryWrapper()

    private val appEventChannel = Channel<Event>(Channel.UNLIMITED)
    private val appEvents = appEventChannel.receiveAsFlow()

    private lateinit var profilesDirectory: File

    private lateinit var tunnelStrategy: AndroidTunnelStrategy

    private var eventSubscription: Closeable? = null

    private var statusSubscription: Closeable? = null

    private var isAppInitialized = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val version = library.partoutVersion()
        Log.i("Passepartout", ">>> $version")

        val bundle = assets.open("bundle.json").bufferedReader().use { it.readText() }
        val constants = assets.open("constants.json").bufferedReader().use { it.readText() }
        profilesDirectory = File(noBackupFilesDir, "profiles-v1").apply {
            mkdirs()
        }

        eventSubscription = ABIEventDispatcher.register(::handleEvent)
        statusSubscription = ABIConnectionStatusDispatcher.register(::handleConnectionStatus)
        library.appInit(
            bundle,
            constants,
            profilesDirectory.absolutePath,
            cacheDir.absolutePath,
            ABIEventDispatcher,
            { code, json ->
                runOnUiThread {
                    if (code == 0) {
                        isAppInitialized = true
                        Log.e("Passepartout", ">>> Started app")
                    } else {
                        Log.e("Passepartout", "Unable to init app (code=$code): $json")
                        destroyApp()
                    }
                }
            }
        )
        tunnelStrategy = AndroidTunnelStrategy(
            context = this,
            vpnServiceClass = PassepartoutVPNService::class.java,
            requestVpnPermission = { permissionIntent ->
                vpnPermissionLauncher.launch(permissionIntent)
            }
        )

        setContent {
            PassepartoutApp(
                events = appEvents,
                onImportProfile = ::openProfileImporter,
                onProfileToggle = ::onProfileToggle,
                onProfilesDelete = ::onProfilesDelete
            )
        }
    }

    override fun onStart() {
        super.onStart()
        library.appOnForeground()
    }

    override fun onDestroy() {
        eventSubscription?.close()
        eventSubscription = null
        statusSubscription?.close()
        statusSubscription = null
        appEventChannel.close()
        if (isAppInitialized) {
            library.appDeinit { _, _ ->
                library.appRelease()
            }
        } else {
            library.appRelease()
        }
        super.onDestroy()
    }

    private fun destroyApp() {
        if (isFinishing || isDestroyed) return
        finishAndRemoveTask()
    }

    private fun handleEvent(eventJSON: String) {
        val event: Event = globalJsonCoder.decodeFromString(eventJSON)
        Log.i("Passepartout", ">>> MainActivity: $event")
        appEventChannel.trySend(event)
    }

    private fun handleConnectionStatus(onStatusJSON: String) {
        val onStatus = globalJsonCoder.decodeFromString<OnConnectionStatus>(onStatusJSON)
        Log.i("Passepartout", ">>> MainActivity: $onStatus")

        val isActive = PassepartoutVPNService.isActive(onStatus.profileId)
        val status = onStatus.status.toAppProfileStatus()
        val activeTunnels = if (isActive) {
            mapOf(
                onStatus.profileId to AppTunnelInfo(
                    id = onStatus.profileId,
                    isEnabled = true,
                    status = status,
                    onDemand = false
                )
            )
        } else {
            emptyMap()
        }
        appEventChannel.trySend(TunnelEventRefresh(activeTunnels))
    }

    private suspend fun onProfileToggle(profileId: String, enabled: Boolean): Boolean {
        return if (enabled) {
            connectTunnel(profileId)
        } else {
            tunnelStrategy.disconnect()
            true
        }
    }

    private fun onProfilesDelete(profileIds: Array<String>): Unit {
        library.appDeleteProfiles(profileIds, { _, _ -> })
    }

    private suspend fun connectTunnel(profileId: String): Boolean {
        val profile = readProfile(profileId)
        if (profile == null) {
            Log.e("Passepartout", "Unable to start missing profile: $profileId")
            return false
        }
        return tunnelStrategy.connect(profile)
    }

    private fun openProfileImporter() {
        profileImportLauncher.launch(PROFILE_MIME_TYPES)
    }

    private fun importProfile(uri: Uri) {
        val profileText = try {
            contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
        } catch (e: Exception) {
            Log.e("Passepartout", "Unable to read profile file: $uri", e)
            null
        } ?: return

        val profileName = displayName(uri) ?: "Imported profile"
        library.appImportProfileText(profileText, profileName) { code, json ->
            runOnUiThread {
                if (code == 0) {
                    library.appOnForeground()
                } else {
                    Log.e("Passepartout", "Import failure (code=$code): $json")
                }
            }
        }
    }

    private val profileImportLauncher = registerForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        if (uri != null) {
            importProfile(uri)
        }
    }

    private val vpnPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        tunnelStrategy.onVpnPermissionResult(result.resultCode == RESULT_OK)
    }

    private companion object {
        const val OBJECTS_DIR = "objects"

        val PROFILE_MIME_TYPES = arrayOf(
            "application/x-openvpn-profile",
            "application/x-wireguard-profile",
            "application/octet-stream",
            "text/*",
            "*/*"
        )
    }

    private fun readProfile(profileId: String): TaggedProfile? {
        val profileFile = File(profilesDirectory, "$OBJECTS_DIR/$profileId.json")
        if (!profileFile.isFile) {
            return null
        }
        return globalJsonCoder.decodeFromString(profileFile.readText())
    }

    private fun displayName(uri: Uri): String? {
        return contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    return@use null
                }
                val displayNameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (displayNameIndex >= 0) {
                    cursor.getString(displayNameIndex)
                } else {
                    null
                }
            }
    }

    private fun ConnectionStatus.toAppProfileStatus(): AppProfileStatus = when (this) {
        ConnectionStatus.disconnected -> AppProfileStatus.disconnected
        ConnectionStatus.connecting -> AppProfileStatus.connecting
        ConnectionStatus.connected -> AppProfileStatus.connected
        ConnectionStatus.disconnecting -> AppProfileStatus.disconnecting
    }
}
