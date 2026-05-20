package com.algoritmico.passepartout

import android.content.Intent
import android.net.VpnService
import android.os.IBinder
import com.algoritmico.passepartout.abi.PassepartoutWrapper
import io.partout.PartoutVpnServiceRuntime
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class PassepartoutVpnService: VpnService() {
    private val runtime by lazy {
        PartoutVpnServiceRuntime(
            logTag = Globals.serviceLogTag,
            service = this,
            engine = engine
        )
    }

    private val engine = object : PartoutVpnServiceRuntime.Engine {
        private val library = PassepartoutWrapper()
        private val lastProfilePath = File(noBackupFilesDir, Globals.PROFILE_LAST_PATH)

        override suspend fun start(
            runtime: PartoutVpnServiceRuntime,
            profileJSON: String
        ): PartoutVpnServiceRuntime.Result = withContext(Dispatchers.IO) {
            PartoutVpnServiceRuntime.Result(
                library.tunnelStart(
                    readAsset(Globals.BUNDLE_FILENAME),
                    readAsset(Globals.CONSTANTS_FILENAME),
                    profileJSON,
                    cacheDir.absolutePath,
                    runtime
                ),
                null
            )
        }

        override suspend fun stop(): PartoutVpnServiceRuntime.Result = withContext(Dispatchers.IO) {
            val result = CompletableDeferred<PartoutVpnServiceRuntime.Result>()
            library.tunnelStop { code, json ->
                result.complete(PartoutVpnServiceRuntime.Result(code, json))
            }
            result.await()
        }

        override suspend fun readLastProfile(): String {
            return withContext(Dispatchers.IO) {
                lastProfilePath.readText()
            }
        }

        override suspend fun writeLastProfile(json: String) {
            withContext(Dispatchers.IO) {
                lastProfilePath.writeText(json)
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return runtime.onStartCommand(intent, flags, startId)
    }

    override fun onDestroy() {
        runtime.onDestroy()
        stopForeground(STOP_FOREGROUND_REMOVE)
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