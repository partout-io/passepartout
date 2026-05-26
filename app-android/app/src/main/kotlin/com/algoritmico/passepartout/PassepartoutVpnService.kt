package com.algoritmico.passepartout

import android.content.Intent
import android.net.VpnService
import android.os.IBinder
import android.util.AtomicFile
import com.algoritmico.passepartout.abi.PassepartoutWrapper
import com.algoritmico.passepartout.abi.helpers.ABIException
import io.partout.PartoutVpnServiceRuntime
import io.partout.vpn.JNITunnelController
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class PassepartoutVpnService: VpnService() {
    private val runtime by lazy {
        PartoutVpnServiceRuntime(
            logTag = Globals.serviceLogTag,
            jniLogTag = Globals.jniLogTag,
            service = this,
            engine = engine
        )
    }

    private val engine = object : PartoutVpnServiceRuntime.Engine {
        private val library = PassepartoutWrapper()
        private val lastProfileFile: File
            get() = File(noBackupFilesDir, Globals.PROFILE_LAST_PATH)

        override suspend fun start(
            controller: JNITunnelController,
            profileJSON: String
        ) = withContext(Dispatchers.IO) {
            // This call retains the controller strongly
            val code = library.tunnelStart(
                readAsset(Globals.BUNDLE_FILENAME),
                readAsset(Globals.CONSTANTS_FILENAME),
                null, // FIXME: Load tunnel preferences
                profileJSON,
                cacheDir.absolutePath,
                controller
            )
            if (code != 0) {
                throw ABIException(code, null)
            }
        }

        override suspend fun stop() = withContext(Dispatchers.IO) {
            val result = CompletableDeferred<Unit>()
            library.tunnelStop { code, _ ->
                if (code != 0) {
                    result.completeExceptionally(ABIException(code, null))
                    return@tunnelStop
                }
                result.complete(Unit)
            }
            result.await()
        }

        override suspend fun readLastProfile(): String {
            return withContext(Dispatchers.IO) {
                AtomicFile(lastProfileFile).openRead().bufferedReader(Charsets.UTF_8).use {
                    it.readText()
                }
            }
        }

        override suspend fun writeLastProfile(json: String) {
            withContext(Dispatchers.IO) {
                val file = AtomicFile(lastProfileFile)
                val stream = file.startWrite()
                try {
                    stream.write(json.toByteArray(Charsets.UTF_8))
                    file.finishWrite(stream)
                } catch (e: Exception) {
                    file.failWrite(stream)
                    throw e
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return runtime.onStartCommand(intent, flags, startId)
    }

    override fun onDestroy() {
        runtime.onDestroy()
        super.onDestroy()
    }

    override fun onRevoke() {
        runtime.onRevoke()
    }

    override fun onBind(intent: Intent?): IBinder? {
        if (intent?.action == SERVICE_INTERFACE) {
            return super.onBind(intent)
        }
        return runtime.onBind(intent)
    }
}
