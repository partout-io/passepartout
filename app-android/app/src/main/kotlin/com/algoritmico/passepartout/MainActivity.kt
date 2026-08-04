// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.os.Bundle
import com.algoritmico.passepartout.context.AppLog
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.lifecycle.lifecycleScope
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.defaultAndroidConstants
import com.algoritmico.passepartout.observables.AppContext
import com.algoritmico.passepartout.ui.PassepartoutApp

class MainActivity : ComponentActivity() {
    private val androidConstants = defaultAndroidConstants
    private val logTag = androidConstants.tags.app
    private lateinit var appContext: AppContext
    private var isProfileImporterOpen = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        appContext = AppContext(
            logTag,
            this,
            lifecycleScope,
            androidConstants = androidConstants,
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
                appContext.diagnosticsObservable,
                appContext.versionObservable,
                appContext.appConfiguration,
                appContext.androidConstants,
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
        runCatchingNonFatal {
            profileImportLauncher.launch(androidConstants.profileImport.mimeTypes.toTypedArray())
        }.onFailure {
            AppLog.e(logTag, "Unable to open profile importer", it)
            isProfileImporterOpen = false
            appContext.errorHandler.report(it)
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
