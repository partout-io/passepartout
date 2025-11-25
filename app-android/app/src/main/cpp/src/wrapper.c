/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <jni.h>
#include <stdlib.h>
#include "passepartout.h"
#include "partout.h"
#include "vpn.h"

JNIEXPORT jint JNICALL
Java_com_algoritmico_partout_NativeLibraryWrapper_passepartoutExample(JNIEnv
* env,
jobject thiz
) {
    return example(50, 70);
}

JNIEXPORT jstring JNICALL
Java_com_algoritmico_partout_NativeLibraryWrapper_partoutVersion(JNIEnv *env, jobject thiz) {
    jstring jmsg = (*env)->NewStringUTF(env, PARTOUT_VERSION);
    return jmsg;
}

JNIEXPORT jlong JNICALL
Java_com_algoritmico_partout_NativeLibraryWrapper_partoutInitialize(JNIEnv *env, jobject thiz, jstring cacheDir) {
    const char *cCacheDir = (*env)->GetStringUTFChars(env, cacheDir, NULL);

    partout_init_args args = { 0 };
    args.cache_dir = cCacheDir;
    args.test_callback = vpn_test_callback;

    void *ctx = partout_init(&args);
    (*env)->ReleaseStringUTFChars(env, cacheDir, cCacheDir);
    return (jlong)ctx;
}

JNIEXPORT void JNICALL
Java_com_algoritmico_partout_NativeLibraryWrapper_partoutDeinitialize(JNIEnv *env, jobject thiz, jlong ctx) {
    partout_deinit((void *)ctx);
}

JNIEXPORT jint JNICALL
Java_com_algoritmico_partout_NativeLibraryWrapper_partoutDaemonStart(JNIEnv *env, jobject thiz, jlong ctx, jstring profile, jobject vpnWrapper) {
    const char *cProfile = (*env)->GetStringUTFChars(env, profile, NULL);

    partout_daemon_start_args args = { 0 };
    args.profile = cProfile;

    // Store global reference of builder wrapper
    jobject jniVPNWrapper = (*env)->NewGlobalRef(env, vpnWrapper);

    // Test working wrapper (direct)
    vpn_test_working_wrapper(jniVPNWrapper);

    // Bind to Kotlin VpnService
    partout_tun_ctrl ctrl = { 0 };
    ctrl.thiz = jniVPNWrapper;
    ctrl.set_tunnel = vpn_set_tunnel;
    ctrl.configure_sockets = vpn_configure_sockets;
    ctrl.clear_tunnel = vpn_clear_tunnel;
    ctrl.test_callback = vpn_test_working_wrapper;
    args.ctrl = &ctrl;

    const int ret = partout_daemon_start((void *)ctx, &args);
    (*env)->ReleaseStringUTFChars(env, profile, cProfile);
    return ret;
}

JNIEXPORT void JNICALL
Java_com_algoritmico_partout_NativeLibraryWrapper_partoutDaemonStop(JNIEnv *env, jobject thiz, jlong ctx) {
    partout_daemon_stop((void *)ctx);
}
