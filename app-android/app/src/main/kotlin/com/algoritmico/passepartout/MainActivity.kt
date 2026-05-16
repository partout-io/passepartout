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
import androidx.lifecycle.lifecycleScope
import com.algoritmico.passepartout.abi.AppABIProfile
import com.algoritmico.passepartout.abi.AppABITunnel
import com.algoritmico.passepartout.abi.PassepartoutWrapper
import com.algoritmico.passepartout.abi.helpers.ABIEventDispatcher
import com.algoritmico.passepartout.abi.models.Event
import com.algoritmico.passepartout.ui.PassepartoutApp
import com.algoritmico.passepartout.ui.ProfileObservable
import com.algoritmico.passepartout.ui.TunnelObservable
import io.partout.abi.TaggedProfile
import io.partout.jni.PartoutTunnel
import kotlinx.coroutines.flow.MutableSharedFlow
import java.io.Closeable
import java.io.File

class MainActivity : ComponentActivity() {
    private val library = PassepartoutWrapper()

    private val appEvents = MutableSharedFlow<Event>(
        replay = APP_EVENT_REPLAY,
        extraBufferCapacity = APP_EVENT_BUFFER_CAPACITY
    )

    private lateinit var profilesDirectory: File

    private lateinit var profileObservable: ProfileObservable

    private lateinit var tunnelObservable: TunnelObservable

    private lateinit var tunnel: PartoutTunnel

    private var eventSubscription: Closeable? = null

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
        profileObservable = ProfileObservable(
            events = appEvents,
            abi = AppABIProfile(library),
            coroutineScope = lifecycleScope
        )
        tunnelObservable = TunnelObservable(
            events = appEvents,
            abi = AppABITunnel(library),
            coroutineScope = lifecycleScope
        )
        tunnel = PartoutTunnel(
            this,
            PassepartoutVpnService::class.java,
            PassepartoutVpnService.channel,
            requestVpnPermission = { permissionIntent ->
                vpnPermissionLauncher.launch(permissionIntent)
            },
            lifecycleScope
        )

        eventSubscription = ABIEventDispatcher.register(::handleEvent)
        val appInitCode = library.appInit(
            bundle,
            constants,
            profilesDirectory.absolutePath,
            cacheDir.absolutePath,
            tunnel,
            ABIEventDispatcher
        )
        if (appInitCode == 0) {
            isAppInitialized = true
            Log.e("Passepartout", ">>> Started app")
        } else {
            Log.e("Passepartout", "Unable to init app (code=$appInitCode)")
            destroyApp()
        }

        setContent {
            PassepartoutApp(
                profileObservable = profileObservable,
                tunnelObservable = tunnelObservable,
                onImportProfile = ::openProfileImporter,
                profileProvider = ::readProfile,
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
        profileObservable.close()
        tunnelObservable.close()
        if (isAppInitialized) {
            library.appDeinit { _, _ -> }
        }
        super.onDestroy()
    }

    private fun destroyApp() {
        if (isFinishing || isDestroyed) return
        finishAndRemoveTask()
    }

    private fun handleEvent(event: Event) {
        Log.i("Passepartout", ">>> MainActivity: $event")
        appEvents.tryEmit(event)
    }

    private fun onProfilesDelete(profileIds: Array<String>): Unit {
        library.appDeleteProfiles(profileIds, { _, _ -> })
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
        tunnel.onVpnPermissionResult(result.resultCode == RESULT_OK)
    }

    private companion object {
        const val APP_EVENT_BUFFER_CAPACITY = 64

        const val APP_EVENT_REPLAY = 64

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
        return try {
            globalJsonCoder.decodeFromString<TaggedProfile>(profileFile.readText())
        } catch (e: Exception) {
            Log.e("Passepartout", "Unable to read profile: $profileId", e)
            null
        }
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

}
