// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.observables.LocalErrorHandler
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

@Composable
fun LogcatView(
    modifier: Modifier = Modifier,
    tags: Collection<String>
) {
    val errorHandler = LocalErrorHandler.current
    val listState = rememberLazyListState()
    var lines by remember(tags) {
        mutableStateOf<List<String>?>(null)
    }

    LaunchedEffect(tags) {
        lines = null
        runCatchingNonFatal {
            Logcat.read(tags)
        }.onSuccess {
            lines = it
        }.onFailure {
            lines = emptyList()
            errorHandler.report(it)
        }
    }

    LaunchedEffect(lines) {
        lines?.lastIndex?.takeIf {
            it >= 0
        }?.let {
            listState.scrollToItem(it)
        }
    }

    when (val currentLines = lines) {
        null -> {
            Box(
                modifier = modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        }
        emptyList<String>() -> {
            Box(
                modifier = modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No content",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        else -> {
            LazyColumn(
                modifier = modifier.fillMaxSize(),
                state = listState,
                contentPadding = PaddingValues(vertical = 8.dp)
            ) {
                itemsIndexed(currentLines) { _, line ->
                    Text(
                        text = line,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.bodySmall,
                        fontFamily = FontFamily.Monospace
                    )
                }
            }
        }
    }
}

private object Logcat {
    private const val HOURS = 6L

    suspend fun read(tags: Collection<String>): List<String> = withContext(Dispatchers.IO) {
        val since = Date(System.currentTimeMillis() - TimeUnit.HOURS.toMillis(HOURS))
        val sinceString = SimpleDateFormat("MM-dd HH:mm:ss.SSS", Locale.US).format(since)
        val command = listOf(
            "logcat",
            "-d",
            "-T",
            sinceString,
            "-v",
            "time"
        ) + tags.map {
            "$it:V"
        } + "*:S"

        val process = ProcessBuilder(command)
            .redirectErrorStream(true)
            .start()
        val lines = process.inputStream.bufferedReader().use {
            it.readLines()
        }
        val exitCode = process.waitFor()
        if (exitCode != 0) {
            error("logcat exited with status $exitCode")
        }
        lines
    }
}
