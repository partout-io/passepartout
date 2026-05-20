package com.algoritmico.passepartout

import android.content.Intent
import android.net.VpnService
import android.os.IBinder
import com.algoritmico.passepartout.abi.PassepartoutWrapper
import io.partout.PartoutVpnServiceRuntime
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class PassepartoutVpnService: VpnService() {
    private val runtime by lazy {
        PartoutVpnServiceRuntime(
            logTag = Globals.serviceLogTag,
            service = this,
            engine = VpnEngine(
                library = PassepartoutWrapper(),
                bundleProvider = {
                    readAsset(Globals.BUNDLE_FILENAME)
                },
                constantsProvider = {
                    readAsset(Globals.CONSTANTS_FILENAME)
                },
                cachePathProvider = {
                    cacheDir.absolutePath
                }
            )
        )
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

    private class VpnEngine(
        private val library: PassepartoutWrapper,
        private val bundleProvider: suspend () -> String,
        private val constantsProvider: suspend () -> String,
        private val cachePathProvider: () -> String
    ) : PartoutVpnServiceRuntime.Engine {
        override suspend fun start(
            runtime: PartoutVpnServiceRuntime,
            profileJSON: String
        ): PartoutVpnServiceRuntime.Result = withContext(Dispatchers.IO) {
            PartoutVpnServiceRuntime.Result(
                library.tunnelStart(
                    bundleProvider(),
                    constantsProvider(),
                    profileJSON,
                    cachePathProvider(),
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
    }
}