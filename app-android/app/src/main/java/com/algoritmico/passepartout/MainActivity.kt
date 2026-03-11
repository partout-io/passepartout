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
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.core.content.ContextCompat
import com.algoritmico.passepartout.DummyVPNService
import com.algoritmico.passepartout.NativeLibraryWrapper

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val wrapper = NativeLibraryWrapper()
        // Start easy, test Partout version
        val version = wrapper.partoutVersion()
        Log.e("Passepartout", ">>> $version")

        // Initialize app and event callback
        var bundle = String(assets.open("bundle.json").readBytes())
        var constants = String(assets.open("constants.json").readBytes())
        var profilesDir = "." // FIXME: #1656, C ABI, profiles dir
        val cachePath = cacheDir.absolutePath
        var eventHandler = MyEventHandler()
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
                { startVpnService() },
                { stopVpnService() }
            )
        }
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
