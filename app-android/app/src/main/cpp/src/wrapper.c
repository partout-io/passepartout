/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <jni.h>
#include <stdlib.h>
#include "passepartout.h"

JNIEXPORT jstring JNICALL
Java_com_algoritmico_passepartout_NativeLibraryWrapper_partoutVersion(JNIEnv *env, jobject thiz) {
    jstring jmsg = (*env)->NewStringUTF(env, psp_partout_version());
    return jmsg;
}

JNIEXPORT jboolean JNICALL
Java_com_algoritmico_passepartout_NativeLibraryWrapper_daemonStart(
        JNIEnv *env,
        jobject thiz,
        jstring cacheDir,
        jstring profile,
        jobject vpnWrapper) {
    const char *cCacheDir = (*env)->GetStringUTFChars(env, cacheDir, NULL);
    const char *cProfile = (*env)->GetStringUTFChars(env, profile, NULL);

    // Store global reference of builder wrapper
    jobject jniVPNWrapper = (*env)->NewGlobalRef(env, vpnWrapper);

    psp_tunnel_start_args args;
    args.cache_dir = cCacheDir;
    args.profile = cProfile;
    args.app_configuration = NULL;
    args.jni_wrapper = jniVPNWrapper;
    const bool ret = psp_tunnel_start(&args, NULL);
    (*env)->ReleaseStringUTFChars(env, profile, cProfile);
    (*env)->ReleaseStringUTFChars(env, cacheDir, cCacheDir);
    return ret;
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_NativeLibraryWrapper_daemonStop(JNIEnv *env, jobject thiz) {
    psp_tunnel_stop(NULL);
}
