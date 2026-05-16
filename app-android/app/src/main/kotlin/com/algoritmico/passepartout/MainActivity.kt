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
import com.algoritmico.passepartout.tunnel.PassepartoutVpnService
import com.algoritmico.passepartout.ui.AppContext
import com.algoritmico.passepartout.ui.PassepartoutApp
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private lateinit var appContext: AppContext

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        appContext = AppContext(
            this,
            lifecycleScope,
            PassepartoutVpnService.channel,
            requestVpnPermission = { permissionIntent ->
                vpnPermissionLauncher.launch(permissionIntent)
            }
        )

        setContent {
            PassepartoutApp(
                appContext.profileObservable,
                appContext.tunnelObservable,
                onImportProfile = ::openProfileImporter
            )
        }
    }

    override fun onStart() {
        super.onStart()
        if (::appContext.isInitialized) {
            appContext.onApplicationActive()
        }
    }

    override fun onDestroy() {
        if (::appContext.isInitialized) {
            appContext.close()
        }
        super.onDestroy()
    }

    private fun openProfileImporter() {
        profileImportLauncher.launch(PROFILE_MIME_TYPES)
    }

    private fun importProfile(uri: Uri) {
        val profileText = try {
            contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
        } catch (e: Exception) {
            Log.e(Globals.logTag, "Unable to read profile file: $uri", e)
            null
        } ?: return

        val profileName = displayName(uri) ?: "Imported profile"
        lifecycleScope.launch {
            runCatching {
                appContext.profileObservable.importText(profileText, profileName)
            }.onSuccess {
                appContext.onApplicationActive()
            }.onFailure {
                Log.e(Globals.logTag, "Import failure: $profileName", it)
            }
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

    private val vpnPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (::appContext.isInitialized) {
            appContext.onVpnPermissionResult(result.resultCode == RESULT_OK)
        }
    }

    private val profileImportLauncher = registerForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        if (uri != null) {
            importProfile(uri)
        }
    }

    private companion object {
        val PROFILE_MIME_TYPES = arrayOf(
            "application/x-openvpn-profile",
            "application/x-wireguard-profile",
            "application/octet-stream",
            "text/*",
            "*/*"
        )
    }
}
