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
import com.algoritmico.partout.NativeLibraryWrapper

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val wrapper = NativeLibraryWrapper()
        val version = wrapper.partoutVersion()
        val sum = wrapper.passepartoutExampleSum()
        val json = wrapper.passepartoutExampleJSON()
        Log.e("Passepartout", ">>> $version")
        Log.e("Passepartout", ">>> psp_example_sum: $sum")
        Log.e("Passepartout", ">>> psp_example_json: $json")

        setContent {
            HelloWorld(
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

@Composable
fun HelloWorld(version: String, startDaemon: () -> Unit, stopDaemon: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                "Hello, ${version}",
                style = MaterialTheme.typography.headlineLarge
            )
            Button(
                onClick = {
                    startDaemon()
                }
            ) {
                Text("Start")
            }
            Button(
                onClick = {
                    stopDaemon()
                }
            ) {
                Text("Stop")
            }
        }
    }
}

@Preview
@Composable
fun PreviewHelloWorld() {
    HelloWorld("World", {}, {})
}