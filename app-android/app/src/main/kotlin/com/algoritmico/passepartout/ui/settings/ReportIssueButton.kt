// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import com.algoritmico.passepartout.R
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.ui.LocalAppConfiguration
import com.algoritmico.passepartout.ui.LocalDiagnosticsObservable
import com.algoritmico.passepartout.ui.LocalErrorHandler
import com.algoritmico.passepartout.ui.theme.LocalTheme
import com.algoritmico.passepartout.ui.theme.ThemeProgressView
import com.algoritmico.passepartout.ui.theme.ThemeProgressViewStyle
import kotlinx.coroutines.launch

private enum class ReportIssueModalRoute {
    Comment
}

@Composable
fun ReportIssueButton(
    modifier: Modifier = Modifier,
    title: String? = null
) {
    val context = LocalContext.current
    val appConfiguration = LocalAppConfiguration.current
    val diagnosticsObservable = LocalDiagnosticsObservable.current
    val errorHandler = LocalErrorHandler.current
    val coroutineScope = rememberCoroutineScope()
    val theme = LocalTheme.current
    var isPending by remember {
        mutableStateOf(false)
    }
    var comment by rememberSaveable {
        mutableStateOf("")
    }
    var modalRoute by rememberSaveable {
        mutableStateOf<ReportIssueModalRoute?>(null)
    }

    if (modalRoute == ReportIssueModalRoute.Comment) {
        ReportIssueCommentDialog(
            comment = comment,
            isPending = isPending,
            onCommentChange = {
                comment = it
            },
            onDismiss = {
                modalRoute = null
            },
            onSubmit = {
                val currentComment = it.trim()
                coroutineScope.launch {
                    isPending = true
                    runCatchingNonFatal {
                        diagnosticsObservable.sendEmail(
                            context = context,
                            appConfiguration = appConfiguration,
                            comment = currentComment
                        )
                    }.onSuccess {
                        comment = ""
                        modalRoute = null
                    }.onFailure {
                        errorHandler.report(it)
                    }
                    isPending = false
                }
            }
        )
    }

    Button(
        enabled = !isPending,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = theme.spacing.large, vertical = theme.spacing.small),
        onClick = {
            modalRoute = ReportIssueModalRoute.Comment
        }
    ) {
        if (isPending) {
            ThemeProgressView(style = ThemeProgressViewStyle.inlineButton)
        } else {
            Text(title ?: stringResource(R.string.views_diagnostics_report_issue_title))
        }
    }
}

@Composable
private fun ReportIssueCommentDialog(
    comment: String,
    isPending: Boolean,
    onCommentChange: (String) -> Unit,
    onDismiss: () -> Unit,
    onSubmit: (String) -> Unit
) {
    AlertDialog(
        onDismissRequest = {
            if (!isPending) {
                onDismiss()
            }
        },
        title = {
            Text(stringResource(R.string.views_diagnostics_report_issue_title))
        },
        text = {
            OutlinedTextField(
                value = comment,
                onValueChange = onCommentChange,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isPending,
                minLines = 3,
                label = {
                    Text(stringResource(R.string.global_nouns_comment))
                }
            )
        },
        confirmButton = {
            TextButton(
                enabled = !isPending && comment.isNotBlank(),
                onClick = {
                    onSubmit(comment)
                }
            ) {
                Text(stringResource(R.string.global_actions_send))
            }
        },
        dismissButton = {
            TextButton(
                enabled = !isPending,
                onClick = onDismiss
            ) {
                Text(stringResource(R.string.global_actions_cancel))
            }
        }
    )
}
