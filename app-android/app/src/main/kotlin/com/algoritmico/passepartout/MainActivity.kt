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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.lifecycleScope
import com.algoritmico.passepartout.extensions.Globals
import com.algoritmico.passepartout.observables.AppContext
import com.algoritmico.passepartout.ui.PassepartoutApp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.nio.ByteBuffer
import java.nio.charset.CharacterCodingException
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets

class MainActivity : ComponentActivity() {
    private lateinit var appContext: AppContext
    private var isProfileImporterOpen = false
    private var importFailureMessage by mutableStateOf<String?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        appContext = AppContext(
            Globals.TAG_APP,
            this,
            lifecycleScope,
            requestVpnPermission = { permissionIntent ->
                vpnPermissionLauncher.launch(permissionIntent)
            }
        )

        setContent {
            PassepartoutApp(
                appContext.profileObservable,
                appContext.tunnelObservable,
                appContext.userPreferencesObservable,
                appContext.configObservable,
                appContext.versionObservable,
                appContext.appConfiguration,
                importFailureMessage = importFailureMessage,
                onDismissImportFailure = {
                    importFailureMessage = null
                },
                onImportProfile = ::openProfileImporter
            )
        }
    }

    override fun onStart() {
        super.onStart()
        if (::appContext.isInitialized && !isProfileImporterOpen) {
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
        isProfileImporterOpen = true
        try {
            profileImportLauncher.launch(PROFILE_MIME_TYPES)
        } catch (e: Exception) {
            isProfileImporterOpen = false
            throw e
        }
    }

    private fun importProfile(uri: Uri) {
        lifecycleScope.launch {
            val profileName = displayName(uri) ?: "Imported profile"
            val profileText = when (val result = readProfileText(uri)) {
                ProfileTextReadResult.Binary -> {
                    importFailureMessage = "$profileName appears to be a binary file."
                    return@launch
                }
                ProfileTextReadResult.Failure -> {
                    importFailureMessage = "Unable to read $profileName."
                    return@launch
                }
                is ProfileTextReadResult.Text -> result.value
            }
            runCatching {
                appContext.profileObservable.importText(profileText, profileName)
            }.onSuccess {
                appContext.onApplicationActive()
            }.onFailure {
                Log.e(Globals.TAG_APP, "Import failure: $profileName", it)
                importFailureMessage = "Unable to import $profileName."
            }
        }
    }

    private suspend fun readProfileText(uri: Uri): ProfileTextReadResult = withContext(Dispatchers.IO) {
        try {
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                ?: return@withContext ProfileTextReadResult.Failure
            bytes.decodeProfileTextOrNull()
                ?.let(ProfileTextReadResult::Text)
                ?: ProfileTextReadResult.Binary
        } catch (e: Exception) {
            Log.e(Globals.TAG_APP, "Unable to read profile file: $uri", e)
            ProfileTextReadResult.Failure
        }
    }

    private suspend fun displayName(uri: Uri): String? = withContext(Dispatchers.IO) {
        try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
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
        } catch (e: Exception) {
            Log.e(Globals.TAG_APP, "Unable to resolve profile file name: $uri", e)
            null
        }
    }

    private val vpnPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (::appContext.isInitialized) {
            appContext.tunnelObservable.onVpnPermissionResult(result.resultCode == RESULT_OK)
        }
    }

    private val profileImportLauncher = registerForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        isProfileImporterOpen = false
        if (uri != null) {
            importProfile(uri)
        } else if (::appContext.isInitialized) {
            appContext.onApplicationActive()
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

private sealed class ProfileTextReadResult {
    data class Text(val value: String) : ProfileTextReadResult()
    data object Binary : ProfileTextReadResult()
    data object Failure : ProfileTextReadResult()
}

private fun ByteArray.decodeProfileTextOrNull(): String? {
    if (hasBinaryControlBytes()) {
        return null
    }
    val decoder = StandardCharsets.UTF_8
        .newDecoder()
        .onMalformedInput(CodingErrorAction.REPORT)
        .onUnmappableCharacter(CodingErrorAction.REPORT)
    return try {
        decoder.decode(ByteBuffer.wrap(this)).toString()
    } catch (_: CharacterCodingException) {
        null
    }
}

private fun ByteArray.hasBinaryControlBytes(): Boolean {
    if (isEmpty()) {
        return false
    }
    var controlCount = 0
    for (byte in this) {
        val value = byte.toInt() and 0xFF
        if (value == 0) {
            return true
        }
        if (value < ASCII_SPACE && value !in TEXT_CONTROL_BYTES) {
            controlCount += 1
        }
    }
    return controlCount > 0 && controlCount * 100 > size
}

private val TEXT_CONTROL_BYTES = setOf(
    '\t'.code,
    '\n'.code,
    '\r'.code,
    '\u000C'.code
)

private const val ASCII_SPACE = 0x20
