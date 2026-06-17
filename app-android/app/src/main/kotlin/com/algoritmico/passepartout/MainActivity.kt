// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.lifecycle.lifecycleScope
import com.algoritmico.passepartout.business.extensions.throwIfFatal
import com.algoritmico.passepartout.context.Files
import com.algoritmico.passepartout.context.Tags
import com.algoritmico.passepartout.observables.AppContext
import com.algoritmico.passepartout.observables.ErrorHandler
import com.algoritmico.passepartout.ui.PassepartoutApp

class MainActivity : ComponentActivity() {
    private val logTag = Tags.APP
    private lateinit var appContext: AppContext
    private var isProfileImporterOpen = false

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
                appContext.errorHandler,
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

    //region Import profile
    private fun openProfileImporter() {
        isProfileImporterOpen = true
        runCatching {
            profileImportLauncher.launch(Files.MIME_TYPES)
        }.onFailure {
            it.throwIfFatal()
            Log.e(logTag, "Unable to open profile importer", it)
            isProfileImporterOpen = false
            ErrorHandler.report(it)
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
    //endregion

    //region Allow VPN
    private val vpnPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (::appContext.isInitialized) {
            appContext.tunnelObservable.onVpnPermissionResult(result.resultCode == RESULT_OK)
        }
    }
    //endregion
}
