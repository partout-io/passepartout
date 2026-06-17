// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout

import android.util.Log
import com.algoritmico.passepartout.context.Tags
import io.partout.abi.PartoutCompletionCallback
import io.partout.vpn.JNITunnelController

interface PassepartoutWrapperProtocol {
    fun partoutInit(tag: String, logsPrivateData: Boolean)
    fun partoutVersion(): String
    fun partoutImportProfile(
        text: String,
        name: String?,
        completion: PartoutCompletionCallback
    )
    fun partoutDaemonStart(
        profile: String,
        cacheDir: String,
        controller: JNITunnelController
    ): Int
    fun partoutDaemonStop(
        completion: PartoutCompletionCallback
    )
}

class PassepartoutWrapper: PassepartoutWrapperProtocol {
    private val wrapper: PassepartoutWrapperProtocol?

    init {
        wrapper = runCatching {
            UnsafePassepartoutWrapper()
        }.getOrElse {
            Log.e(Tags.PARTOUT_JNI, "Unable to load JNI library", it)
            null
        }
    }

    override fun partoutInit(tag: String, logsPrivateData: Boolean) {
        wrapper?.partoutInit(tag, logsPrivateData)
    }

    override fun partoutVersion(): String {
        if (wrapper == null) {
            return "x.y.z"
        }
        return wrapper.partoutVersion()
    }

    override fun partoutDaemonStart(
        profile: String,
        cacheDir: String,
        controller: JNITunnelController
    ): Int {
        if (wrapper == null) {
            return -1
        }
        return wrapper.partoutDaemonStart(profile, cacheDir, controller)
    }

    override fun partoutDaemonStop(completion: PartoutCompletionCallback) {
        if (wrapper == null) {
            completion.onComplete(-1, null)
            return
        }
        wrapper.partoutDaemonStop(completion)
    }

    override fun partoutImportProfile(
        text: String,
        name: String?,
        completion: PartoutCompletionCallback
    ) {
        if (wrapper == null) {
            completion.onComplete(-1, null)
            return
        }
        wrapper.partoutImportProfile(text, name, completion)
    }
}

private class UnsafePassepartoutWrapper: PassepartoutWrapperProtocol {
    override external fun partoutInit(tag: String, logsPrivateData: Boolean)
    override external fun partoutVersion(): String
    override external fun partoutImportProfile(
        text: String,
        name: String?,
        completion: PartoutCompletionCallback
    )
    override external fun partoutDaemonStart(
        profile: String,
        cacheDir: String,
        controller: JNITunnelController
    ): Int
    override external fun partoutDaemonStop(
        completion: PartoutCompletionCallback
    )

    companion object {
        init {
            // Name of the NDK .so without "lib" prefix or ".so"
            System.loadLibrary("passepartout_wrapper")
        }
    }
}