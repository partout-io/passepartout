// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.lifecycleScope
import com.algoritmico.passepartout.injection.Tags
import com.algoritmico.passepartout.observables.AppContext
import com.algoritmico.passepartout.observables.ErrorHandler
import com.algoritmico.passepartout.observables.ProfileImporter
import com.algoritmico.passepartout.ui.PassepartoutApp

class MainActivity : ComponentActivity() {
    private val logTag = Tags.APP
    private lateinit var appContext: AppContext
    private var isProfileImporterOpen = false
    private var importFailureMessage by mutableStateOf<String?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        appContext = AppContext(
            logTag,
            this,
            lifecycleScope,
            requestVpnPermission = { permissionIntent ->
                vpnPermissionLauncher.launch(permissionIntent)
            }
        )
        setContent {
            PassepartoutApp(
                logTag,
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
        runCatching {
            profileImportLauncher.launch(ProfileImporter.MIME_TYPES)
        }.onFailure {
            if (it !is Exception) {
                throw it
            }
            Log.e(logTag, "Unable to open profile importer", it)
            isProfileImporterOpen = false
            ErrorHandler.report(it)
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
        if (uri != null && ::appContext.isInitialized) {
            appContext.profileImporter.importProfile(uri)
        } else if (::appContext.isInitialized) {
            appContext.onApplicationActive()
        }
    }
}
