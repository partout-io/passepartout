// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.context.LocalConstants
import com.algoritmico.passepartout.observables.LocalDiagnosticsObservable
import com.algoritmico.passepartout.observables.LocalErrorHandler

@Composable
fun LogcatView(
    modifier: Modifier = Modifier,
    tags: Collection<String>
) {
    val diagnosticsObservable = LocalDiagnosticsObservable.current
    val errorHandler = LocalErrorHandler.current
    val listState = rememberLazyListState()
    var lines by remember(tags) {
        mutableStateOf<List<String>?>(null)
    }

    LaunchedEffect(tags) {
        lines = null
        runCatchingNonFatal {
            diagnosticsObservable.logcat(tags, LocalConstants.LOGCAT_VIEW_HOURS)
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
        null -> SettingsProgressView(modifier = modifier)
        emptyList<String>() -> SettingsEmptyContentView(modifier = modifier)
        else -> LogcatListView(
            modifier = modifier,
            lines = currentLines,
            state = listState
        )
    }
}

@Composable
private fun LogcatListView(
    modifier: Modifier,
    lines: List<String>,
    state: LazyListState
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        state = state,
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        itemsIndexed(lines) { _, line ->
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
