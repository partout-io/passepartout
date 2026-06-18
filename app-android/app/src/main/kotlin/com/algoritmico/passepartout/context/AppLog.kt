// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.context

import android.util.Log

enum class AppLogLevel {
    DEBUG,
    INFO,
    WARN,
    ERROR
}

interface AppLogBackend {
    fun log(
        level: AppLogLevel,
        tag: String,
        message: String,
        error: Throwable? = null
    )
}

object AppLog {
    @Volatile
    private var backend: AppLogBackend = AndroidAppLogBackend

    fun setBackend(backend: AppLogBackend): AppLogBackend {
        val previous = this.backend
        this.backend = backend
        return previous
    }

    fun resetBackend() {
        backend = AndroidAppLogBackend
    }

    fun d(tag: String, message: String, error: Throwable? = null) {
        backend.log(AppLogLevel.DEBUG, tag, message, error)
    }

    fun i(tag: String, message: String, error: Throwable? = null) {
        backend.log(AppLogLevel.INFO, tag, message, error)
    }

    fun w(tag: String, message: String, error: Throwable? = null) {
        backend.log(AppLogLevel.WARN, tag, message, error)
    }

    fun e(tag: String, message: String, error: Throwable? = null) {
        backend.log(AppLogLevel.ERROR, tag, message, error)
    }
}

object NoOpAppLogBackend : AppLogBackend {
    override fun log(
        level: AppLogLevel,
        tag: String,
        message: String,
        error: Throwable?
    ) = Unit
}

private object AndroidAppLogBackend : AppLogBackend {
    override fun log(
        level: AppLogLevel,
        tag: String,
        message: String,
        error: Throwable?
    ) {
        write {
            when (level) {
                AppLogLevel.DEBUG -> {
                    if (error != null) Log.d(tag, message, error) else Log.d(tag, message)
                }
                AppLogLevel.INFO -> {
                    if (error != null) Log.i(tag, message, error) else Log.i(tag, message)
                }
                AppLogLevel.WARN -> {
                    if (error != null) Log.w(tag, message, error) else Log.w(tag, message)
                }
                AppLogLevel.ERROR -> {
                    if (error != null) Log.e(tag, message, error) else Log.e(tag, message)
                }
            }
        }
    }

    private inline fun write(block: () -> Int) {
        try {
            block()
        } catch (error: RuntimeException) {
            // Local JVM tests use mockable android.jar, where Log methods throw.
            if (error.message?.contains("not mocked") != true) {
                throw error
            }
        }
    }
}
