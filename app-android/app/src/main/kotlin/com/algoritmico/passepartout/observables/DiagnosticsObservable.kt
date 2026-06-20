// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.annotation.SuppressLint
import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import com.algoritmico.passepartout.business.extensions.body
import com.algoritmico.passepartout.business.extensions.issues
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.extensions.subject
import com.algoritmico.passepartout.business.extensions.versionString
import com.algoritmico.passepartout.context.AndroidConstants
import com.algoritmico.passepartout.context.androidSystemInformation
import com.algoritmico.passepartout.models.AppConfiguration
import com.algoritmico.passepartout.models.Issue
import com.algoritmico.passepartout.models.IssueAttachment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import java.util.concurrent.TimeUnit

class DiagnosticsObservable(
    private val logTags: AndroidConstants.LogTags,
    private val diagnosticsConstants: AndroidConstants.Diagnostics
) {
    suspend fun issue(
        context: Context,
        appConfiguration: AppConfiguration,
        comment: String
    ): Issue = coroutineScope {
        val appContext = context.applicationContext
        val appLog = async {
            logcat(logTags.appTags, diagnosticsConstants.logcatViewHours)
                .toIssueAttachment(appConfiguration.appLogPath)
        }
        val tunnelLog = async {
            logcat(logTags.serviceTags, diagnosticsConstants.logcatViewHours)
                .toIssueAttachment(appConfiguration.tunnelLogPath)
        }
        val exitReasons = async(Dispatchers.IO) {
            appContext.exitReasonsAttachment(diagnosticsConstants)
        }
        val systemInformation = context.androidSystemInformation()
        Issue(
            id = UUID.randomUUID(),
            comment = comment,
            appLine = "${appConfiguration.bundle.displayName} ${appConfiguration.bundle.versionString} [${appConfiguration.bundle.distributionTarget}]",
            purchasedProducts = emptyList(),
            providerLastUpdates = emptyMap(),
            attachments = listOfNotNull(
                appLog.await(),
                tunnelLog.await(),
                exitReasons.await()
            ),
            osLine = systemInformation.osLine,
            deviceLine = systemInformation.deviceLine
        )
    }

    suspend fun sendEmail(
        context: Context,
        appConfiguration: AppConfiguration,
        comment: String
    ) {
        val report = issue(
            context = context.applicationContext,
            appConfiguration = appConfiguration,
            comment = comment
        )
        val attachments = withContext(Dispatchers.IO) {
            report.attachmentUris(context, diagnosticsConstants)
        }
        context.openIssueEmail(
            appConfiguration = appConfiguration,
            issue = report,
            attachments = attachments,
            diagnosticsConstants = diagnosticsConstants
        )
    }

    suspend fun logcat(
        tags: Collection<String>,
        hours: Long
    ): List<String> = coroutineScope {
        val process = withContext(Dispatchers.IO) {
            ProcessBuilder(logcatCommand(tags, hours))
                .redirectErrorStream(true)
                .start()
        }
        val output = async(Dispatchers.IO) {
            process.inputStream.bufferedReader().use {
                it.readLines()
            }
        }
        runCatchingNonFatal {
            val timeoutMillis = logTimeoutMillis
            val didFinish = withContext(Dispatchers.IO) {
                process.waitFor(timeoutMillis, TimeUnit.MILLISECONDS)
            }
            if (!didFinish) {
                process.destroy()
                if (!process.waitFor(diagnosticsConstants.logcatDestroyTimeoutMillis, TimeUnit.MILLISECONDS)) {
                    process.destroyForcibly()
                }
                error("logcat timed out")
            }

            val lines = output.await()
            val exitCode = process.exitValue()
            if (exitCode != 0) {
                error("logcat exited with status $exitCode")
            }
            lines
        }.also {
            if (process.isAlive) {
                process.destroyForcibly()
            }
            output.cancel()
        }.getOrElse {
            throw it
        }
    }

    private val logTimeoutMillis: Long
        get() = diagnosticsConstants.logcatTimeoutMillis

    private fun logcatCommand(
        tags: Collection<String>,
        hours: Long
    ): List<String> {
        val since = Date(System.currentTimeMillis() - TimeUnit.HOURS.toMillis(hours))
        val sinceString = SimpleDateFormat("MM-dd HH:mm:ss.SSS", Locale.US).format(since)
        return listOf(
            "logcat",
            "-d",
            "-T",
            sinceString,
            "-v",
            "time"
        ) + tags.map {
            "$it:I" // INFO
        } + "*:S"
    }

    private fun List<String>.toIssueAttachment(filename: String): IssueAttachment? {
        if (isEmpty()) {
            return null
        }
        val content = joinToString(separator = "\n")
            .toByteArray(Charsets.UTF_8)
        return IssueAttachment(
            filename = filename,
            content = content
        )
    }
}

private fun Context.openIssueEmail(
    appConfiguration: AppConfiguration,
    issue: Issue,
    attachments: List<Uri>,
    diagnosticsConstants: AndroidConstants.Diagnostics
) {
    val intent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
        type = diagnosticsConstants.issueEmailMimeType
        putExtra(Intent.EXTRA_EMAIL, arrayOf(appConfiguration.constants.emails.issues))
        putExtra(Intent.EXTRA_SUBJECT, issue.subject)
        putExtra(Intent.EXTRA_TEXT, issue.body)
        if (attachments.isNotEmpty()) {
            putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(attachments))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            clipData = attachments.toClipData(this@openIssueEmail, diagnosticsConstants)
        }
    }
    startActivity(Intent.createChooser(intent, diagnosticsConstants.issueEmailChooserTitle))
}

private fun Issue.attachmentUris(
    context: Context,
    diagnosticsConstants: AndroidConstants.Diagnostics
): List<Uri> {
    return attachments.map {
        it.toAttachmentUri(context, diagnosticsConstants)
    }
}

private fun IssueAttachment.toAttachmentUri(
    context: Context,
    diagnosticsConstants: AndroidConstants.Diagnostics
): Uri {
    val directory = File(context.cacheDir, diagnosticsConstants.issueCacheDirectory).apply {
        mkdirs()
    }
    val file = File(directory, File(filename).name).apply {
        writeBytes(content)
    }
    return FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        file
    )
}

private fun List<Uri>.toClipData(
    context: Context,
    diagnosticsConstants: AndroidConstants.Diagnostics
): ClipData? {
    val first = firstOrNull() ?: return null
    return ClipData.newUri(context.contentResolver, diagnosticsConstants.issueLogsClipLabel, first).apply {
        drop(1).forEach {
            addItem(ClipData.Item(it))
        }
    }
}

private val AppConfiguration.appLogPath: String
    get() = constants.log.filenames.app

private val AppConfiguration.tunnelLogPath: String
    get() = constants.log.filenames.tunnel

@SuppressLint("NewApi")
private fun Context.exitReasonsAttachment(
    diagnosticsConstants: AndroidConstants.Diagnostics
): IssueAttachment? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
        return null
    }
    val exitReasons = runCatchingNonFatal {
        getSystemService(ActivityManager::class.java)
            ?.getHistoricalProcessExitReasons(packageName, 0, diagnosticsConstants.exitReasonsLimit)
    }.getOrNull()
        ?.takeIf {
            it.isNotEmpty()
        } ?: return null

    return IssueAttachment(
        filename = diagnosticsConstants.exitReasonsFilename,
        content = exitReasons.toExitReasonsText().toByteArray(Charsets.UTF_8)
    )
}

@SuppressLint("NewApi")
private fun List<ApplicationExitInfo>.toExitReasonsText(): String {
    return mapIndexed { index, exitInfo ->
        exitInfo.toDiagnosticsText(index)
    }.joinToString(separator = "\n")
}

@SuppressLint("NewApi")
private fun ApplicationExitInfo.toDiagnosticsText(index: Int): String {
    return buildString {
        appendLine("#${index + 1}")
        appendLine("timestamp: ${exitReasonTimestampFormatter.format(Date(timestamp))}")
        appendLine("process: ${processName ?: "unknown"}")
        appendLine("pid: $pid")
        appendLine("reason: ${reason.exitReasonDescription()} ($reason)")
        appendLine("status: $status")
        appendLine("importance: $importance")
        appendLine("pss: $pss KB")
        appendLine("rss: $rss KB")
        val exitDescription = description
        if (!exitDescription.isNullOrBlank()) {
            appendLine("description: $exitDescription")
        }
    }
}

@SuppressLint("NewApi")
private fun Int.exitReasonDescription(): String {
    return when (this) {
        ApplicationExitInfo.REASON_ANR -> "ANR"
        ApplicationExitInfo.REASON_CRASH -> "crash"
        ApplicationExitInfo.REASON_CRASH_NATIVE -> "native crash"
        ApplicationExitInfo.REASON_DEPENDENCY_DIED -> "dependency died"
        ApplicationExitInfo.REASON_EXCESSIVE_RESOURCE_USAGE -> "excessive resource usage"
        ApplicationExitInfo.REASON_EXIT_SELF -> "exit self"
        ApplicationExitInfo.REASON_FREEZER -> "freezer"
        ApplicationExitInfo.REASON_INITIALIZATION_FAILURE -> "initialization failure"
        ApplicationExitInfo.REASON_LOW_MEMORY -> "low memory"
        ApplicationExitInfo.REASON_OTHER -> "other"
        ApplicationExitInfo.REASON_PACKAGE_STATE_CHANGE -> "package state change"
        ApplicationExitInfo.REASON_PACKAGE_UPDATED -> "package updated"
        ApplicationExitInfo.REASON_PERMISSION_CHANGE -> "permission change"
        ApplicationExitInfo.REASON_SIGNALED -> "signaled"
        ApplicationExitInfo.REASON_UNKNOWN -> "unknown"
        ApplicationExitInfo.REASON_USER_REQUESTED -> "user requested"
        ApplicationExitInfo.REASON_USER_STOPPED -> "user stopped"
        else -> "unrecognized"
    }
}

private val exitReasonTimestampFormatter: SimpleDateFormat
    get() = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS Z", Locale.US)
