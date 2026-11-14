// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.content.Intent
import com.algoritmico.passepartout.business.models.ProfileImporterInput
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import com.algoritmico.passepartout.context.AppLog
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import kotlinx.coroutines.launch
import androidx.core.content.ContextCompat
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.defaultAndroidConstants
import com.algoritmico.passepartout.ui.PassepartoutApp

class MainActivity : ComponentActivity() {
    private val androidConstants = defaultAndroidConstants
    private val logTag = androidConstants.tags.app
    private val app get() = application as PassepartoutApplication
    private val appContext get() = app.appContext
    private var isProfileImporterOpen = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        isProfileImporterOpen = savedInstanceState?.getBoolean("isProfileImporterOpen") ?: false
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.RESUMED) {
                appContext.vpnPermissionObservable.state.collect {
                    val request = appContext.vpnPermissionObservable.takePendingRequest()
                        ?: return@collect
                    runCatchingNonFatal {
                        vpnPermissionLauncher.launch(request)
                    }.onFailure {
                        appContext.onVpnPermissionResult(false)
                        appContext.errorHandler.report(it)
                    }
                }
            }
        }
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
                profileImporter = appContext.profileImporter,
                onImportProfile = ::openProfileImporter
            )
        }
        if (savedInstanceState == null) {
            requestNotificationPermission()
            importProfileFromIntent(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        importProfileFromIntent(intent)
    }

    private fun importProfileFromIntent(intent: Intent) {
        if (intent.action != Intent.ACTION_VIEW) return
        val uri = intent.data ?: return
        if (uri.scheme != "content" && uri.scheme != "file") return
        appContext.profileImporter.importProfiles(listOf(ProfileImporterInput.File(uri)))
    }

    override fun onStart() {
        super.onStart()
        if (!isProfileImporterOpen) {
            appContext.onApplicationActive()
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putBoolean("isProfileImporterOpen", isProfileImporterOpen)
        super.onSaveInstanceState(outState)
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
        ActivityResultContracts.OpenMultipleDocuments()
    ) { uris ->
        isProfileImporterOpen = false
        if (uris.isNotEmpty()) {
            appContext.profileImporter.importProfiles(uris.map { ProfileImporterInput.File(it) })
        } else {
            appContext.onApplicationActive()
        }
    }
    //endregion

    //region Allow notifications
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return
        }
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
    }

    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (!granted) {
            AppLog.d(logTag, "Notification permission was not granted")
        }
    }
    //endregion

    //region Allow VPN
    private val vpnPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        appContext.onVpnPermissionResult(result.resultCode == RESULT_OK)
    }
    //endregion
}
