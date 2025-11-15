package com.algoritmico.partout

import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log

class VpnWrapper: AutoCloseable {
    private val service: VpnService
    private val builder: VpnService.Builder
    private var descriptor: ParcelFileDescriptor?

    constructor(service: VpnService) {
        this.service = service
        builder = service.Builder()
        descriptor = null
    }

    fun testWorking() {
        Log.e("Passepartout", ">>> VpnServiceBuilderWrapper: Working!")
    }

    fun setAddress(address: String, prefix: Int) {
        builder.addAddress(address, prefix)
    }

    fun build(remoteFds: Array<Int>): Int? {
        assert(descriptor == null)

        // Protect remote socket to escape tunnel
        Log.e("Passepartout", ">>> VpnServiceBuilderWrapper: Building with remoteFds = " + remoteFds + " (" + remoteFds.size + ")")
        remoteFds.forEach {
            service.protect(it)
        }

        // FIXME: hardcode network settings to try tun fd
//        builder.setSession()
        builder
            // OpenVPN
            .addAddress("10.8.0.2", 24)
            .addRoute("10.8.0.0", 24)
            // WireGuard
//            .addAddress("192.168.30.2", 32)
            // All
            .addRoute("0.0.0.0", 0)
            .addDnsServer("1.1.1.1")

        // IMPORTANT: this is a requirement for VirtualTunnelInterface
        //
        // The effect of not doing this is the tun connection dying
        // on the first 0, because the fd is non-blocking by
        // default (EAGAIN).
        //
        // https://developer.android.com/reference/android/net/VpnService.Builder#setBlocking(boolean)
        //
        // Sets the VPN interface's file descriptor to be in blocking/non-blocking
        // mode. By default, the file descriptor returned by establish() is non-blocking.
        builder.setBlocking(true)

        // Get fd to tun device
        Log.e("Passepartout", ">>> VpnServiceBuilderWrapper: Establishing...")
        descriptor = builder.establish()
        if (descriptor == null) {
            Log.e("Passepartout", ">>> VpnServiceBuilderWrapper: Unable to establish")
            return null
        }

        // Success
        val fd = descriptor?.fd
        Log.e("Passepartout", ">>> VpnServiceBuilderWrapper: Established descriptor: " + fd)
//        descriptor?.detachFd()
        return fd
    }

    fun configureSockets(fds: Array<Int>) {
        Log.e("Passepartout", ">>> VpnServiceBuilderWrapper: Configuring with fds = " + fds + " (" + fds.size + ")")
        fds.forEach {
            service.protect(it)
        }
    }

    override fun close() {
        Log.e("Passepartout", ">>> VpnServiceBuilderWrapper: Closing...")
        descriptor?.close()
        descriptor = null
    }
}
