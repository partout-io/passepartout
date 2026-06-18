// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.observables

import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import com.algoritmico.passepartout.business.extensions.body
import com.algoritmico.passepartout.business.extensions.issues
import com.algoritmico.passepartout.business.extensions.runCatchingNonFatal
import com.algoritmico.passepartout.business.extensions.subject
import com.algoritmico.passepartout.business.extensions.versionString
import com.algoritmico.passepartout.context.LocalConstants
import com.algoritmico.passepartout.context.Tags
import com.algoritmico.passepartout.context.androidSystemInformation
import com.algoritmico.passepartout.models.AppConfiguration
import com.algoritmico.passepartout.models.Issue
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

class DiagnosticsObservable {
    suspend fun issue(
        context: Context,
        appConfiguration: AppConfiguration,
        comment: String
    ): Issue = coroutineScope {
        val appLog = async {
            logcat(Tags.appTags, LocalConstants.LOGCAT_VIEW_HOURS).toLogData()
        }
        val tunnelLog = async {
            logcat(Tags.serviceTags, LocalConstants.LOGCAT_VIEW_HOURS).toLogData()
        }
        val systemInformation = context.androidSystemInformation()
        Issue(
            id = UUID.randomUUID(),
            comment = comment,
            appLine = "${appConfiguration.bundle.displayName} ${appConfiguration.bundle.versionString} [${appConfiguration.bundle.distributionTarget}]",
            purchasedProducts = emptyList(),
            providerLastUpdates = emptyMap(),
            appLog = appLog.await(),
            tunnelLog = tunnelLog.await(),
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
            report.attachmentUris(context, appConfiguration)
        }
        context.openIssueEmail(
            appConfiguration = appConfiguration,
            issue = report,
            attachments = attachments
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
                if (!process.waitFor(LocalConstants.LOGCAT_DESTROY_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS)) {
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
        get() = (LocalConstants.LOGCAT_TIMEOUT_SECONDS * 1000.0)
            .toLong()
            .coerceAtLeast(1L)

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
            "$it:V"
        } + "*:S"
    }

    private fun List<String>.toLogData(): ByteArray? {
        if (isEmpty()) {
            return null
        }
        return joinToString(separator = "\n")
            .toByteArray(Charsets.UTF_8)
    }
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
