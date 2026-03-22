package com.algoritmico.passepartout

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.algoritmico.passepartout.abi.AppProfileHeader

@Composable
fun HelloWorldView(
    version: String,
    headers: State<Map<String, AppProfileHeader>>,
    startDaemon: () -> Unit,
    stopDaemon: () -> Unit,
    importProfile: () -> Unit
) {
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
                onClick = { startDaemon() }
            ) {
                Text("Start")
            }
            Button(
                onClick = {  stopDaemon() }
            ) {
                Text("Stop")
            }
            Button(
                onClick = {  importProfile() }
            ) {
                Text("Import")
            }
            LazyColumn {
                items(
//                    items = arrayOf("One", "Two")
                    headers.value.values.toList().sortedBy { it.name },
                    key = { it.id }
                ) { header ->
//                    Text(header)
//                    Text(header.name)
                    Text(header.id)
                }
            }
        }
    }
}

@Preview
@Composable
fun PreviewHelloWorld() {
    HelloWorldView(
        "World",
        remember { mutableStateOf<Map<String, AppProfileHeader>>(emptyMap()) },
        {}, {}, {}
    )
}