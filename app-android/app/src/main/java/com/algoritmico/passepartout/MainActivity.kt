// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.mutableStateOf
import androidx.core.content.ContextCompat
import com.algoritmico.passepartout.abi.ABIEventCallback
import com.algoritmico.passepartout.abi.ABI_AppProfileHeader
import com.algoritmico.passepartout.abi.ABI_Event
import com.algoritmico.passepartout.abi.NativeLibraryWrapper
import com.algoritmico.passepartout.abi.ABI_ProfileEvent_Refresh
import kotlinx.serialization.json.Json

val json = Json {
    ignoreUnknownKeys = true
}

class MainActivity : ComponentActivity(), ABIEventCallback {
    val wrapper = NativeLibraryWrapper()
    var headers = mutableStateOf<Map<String, ABI_AppProfileHeader>>(emptyMap())

    override fun onEvent(eventCtx: Any?, eventJSON: String) {
        val event: ABI_Event = json.decodeFromString(eventJSON)
        Log.i("Passepartout", ">>> MainActivity: $event")
        when (event) {
            is ABI_ProfileEvent_Refresh -> {
                headers.value = event.headers
            }
            else -> {
                // Other events
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Start easy, test Partout version
        val version = wrapper.partoutVersion()
        Log.e("Passepartout", ">>> $version")

        // Initialize app and event callback
        var bundle = String(assets.open("bundle.json").readBytes())
        var constants = String(assets.open("constants.json").readBytes())
        var profilesDir = "." // FIXME: #1656, C ABI, profiles dir
        val cachePath = cacheDir.absolutePath
        var eventHandler = this
        wrapper.appInit(
            bundle,
            constants,
            profilesDir,
            cachePath,
            this,
            eventHandler
        )

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
        // Check for permission grant
        val permissionIntent = VpnService.prepare(this)
        if (permissionIntent != null) {
            vpnPermissionLauncher.launch(permissionIntent)
            return
        }
        // Permission already granted
        val startIntent = Intent(this, DummyVPNService::class.java)
        ContextCompat.startForegroundService(this, startIntent)
    }

    fun stopVpnService() {
        val stopIntent = Intent(this, DummyVPNService::class.java)
        stopIntent.action = "STOP_VPN"
        ContextCompat.startForegroundService(this, stopIntent)
        // This calls onDestroy abruptly and may prevent proper VPN cleanup
//        stopService(stopIntent)
    }

    fun importProfile() {
        val file = String(assets.open("vps.conf").readBytes())
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
        if (result.resultCode == RESULT_OK) {
            // User granted VPN permission
            startVpnService()
        } else {
            // User denied VPN permission
        }
    }
}
