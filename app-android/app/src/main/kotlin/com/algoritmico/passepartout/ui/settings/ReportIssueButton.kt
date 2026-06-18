// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui.settings

import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import com.algoritmico.passepartout.business.extensions.body
import com.algoritmico.passepartout.business.extensions.issues
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.extensions.subject
import com.algoritmico.passepartout.models.AppConfiguration
import com.algoritmico.passepartout.models.Issue
import com.algoritmico.passepartout.observables.DiagnosticsObservable
import com.algoritmico.passepartout.observables.ErrorHandler
import com.algoritmico.passepartout.observables.LocalAppConfiguration
import com.algoritmico.passepartout.observables.LocalDiagnosticsObservable
import com.algoritmico.passepartout.observables.LocalErrorHandler
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

private enum class ReportIssueModalRoute {
    Comment
}

@Composable
fun ReportIssueButton(
    modifier: Modifier = Modifier,
    title: String = "Report issue"
) {
    val context = LocalContext.current
    val appConfiguration = LocalAppConfiguration.current
    val diagnosticsObservable = LocalDiagnosticsObservable.current
    val errorHandler = LocalErrorHandler.current
    val coroutineScope = rememberCoroutineScope()
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
                    try {
                        if (sendEmail(
                                context = context,
                                appConfiguration = appConfiguration,
                                diagnosticsObservable = diagnosticsObservable,
                                errorHandler = errorHandler,
                                comment = currentComment
                            )
                        ) {
                            comment = ""
                            modalRoute = null
                        }
                    } finally {
                        isPending = false
                    }
                }
            }
        )
    }

    Button(
        enabled = !isPending,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        onClick = {
            modalRoute = ReportIssueModalRoute.Comment
        }
    ) {
        if (isPending) {
            CircularProgressIndicator(
                modifier = Modifier.size(18.dp),
                strokeWidth = 2.dp,
                color = MaterialTheme.colorScheme.onPrimary
            )
        } else {
            Text(title)
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
            Text("Report issue")
        },
        text = {
            OutlinedTextField(
                value = comment,
                onValueChange = onCommentChange,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isPending,
                minLines = 3,
                label = {
                    Text("Comment")
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
                Text("Send")
            }
        },
        dismissButton = {
            TextButton(
                enabled = !isPending,
                onClick = onDismiss
            ) {
                Text("Cancel")
            }
        }
    )
}

private suspend fun sendEmail(
    context: Context,
    appConfiguration: AppConfiguration,
    diagnosticsObservable: DiagnosticsObservable,
    errorHandler: ErrorHandler,
    comment: String
): Boolean {
    val issue = runCatchingNonFatal {
        diagnosticsObservable.issue(
            context = context.applicationContext,
            appConfiguration = appConfiguration,
            comment = comment
        )
    }.onFailure {
        errorHandler.report(it)
    }.getOrNull() ?: return false

    val attachments = withContext(Dispatchers.IO) {
        runCatchingNonFatal {
            issue.attachmentUris(context, appConfiguration)
        }
    }.onFailure {
        errorHandler.report(it)
    }.getOrNull() ?: return false

    return runCatchingNonFatal {
        context.openIssueEmail(
            appConfiguration = appConfiguration,
            issue = issue,
            attachments = attachments
        )
    }.onFailure {
        errorHandler.report(it)
    }.getOrNull() != null
}

private fun Context.openIssueEmail(
    appConfiguration: AppConfiguration,
    issue: Issue,
    attachments: List<Uri>
) {
    val intent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
        type = "message/rfc822"
        putExtra(Intent.EXTRA_EMAIL, arrayOf(appConfiguration.constants.emails.issues))
        putExtra(Intent.EXTRA_SUBJECT, issue.subject)
        putExtra(Intent.EXTRA_TEXT, issue.body)
        if (attachments.isNotEmpty()) {
            putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(attachments))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            clipData = attachments.toClipData(this@openIssueEmail)
        }
    }
    startActivity(Intent.createChooser(intent, "Report issue"))
}

private fun Issue.attachmentUris(
    context: Context,
    appConfiguration: AppConfiguration
): List<Uri> {
    return listOfNotNull(
        appLog?.toAttachmentUri(context, appConfiguration.appLogPath),
        tunnelLog?.toAttachmentUri(context, appConfiguration.tunnelLogPath)
    )
}

private fun ByteArray.toAttachmentUri(
    context: Context,
    fileName: String
): Uri {
    val directory = File(context.cacheDir, "issue").apply {
        mkdirs()
    }
    val file = File(directory, File(fileName).name).apply {
        writeBytes(this@toAttachmentUri)
    }
    return FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        file
    )
}

private fun List<Uri>.toClipData(context: Context): ClipData? {
    val first = firstOrNull() ?: return null
    return ClipData.newUri(context.contentResolver, "Issue logs", first).apply {
        drop(1).forEach {
            addItem(ClipData.Item(it))
        }
    }
}

private val AppConfiguration.appLogPath: String
    get() = constants.log.filenames.app

private val AppConfiguration.tunnelLogPath: String
    get() = constants.log.filenames.tunnel
