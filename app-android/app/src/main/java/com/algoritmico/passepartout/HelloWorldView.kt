package com.algoritmico.passepartout

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

@Composable
fun HelloWorldView(version: String, startDaemon: () -> Unit, stopDaemon: () -> Unit) {
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
    HelloWorldView("World", {}, {})
}