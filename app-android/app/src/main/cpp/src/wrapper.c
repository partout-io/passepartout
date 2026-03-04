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
        jstring bundle,
        jstring constants,
        jstring profile,
        jstring cacheDir,
        jobject vpnWrapper) {
    const char *cBundle = (*env)->GetStringUTFChars(env, bundle, NULL);
    const char *cConstants = (*env)->GetStringUTFChars(env, constants, NULL);
    const char *cProfile = (*env)->GetStringUTFChars(env, profile, NULL);
    const char *cCacheDir = (*env)->GetStringUTFChars(env, cacheDir, NULL);

    // Store global reference of builder wrapper
    jobject jniVPNWrapper = (*env)->NewGlobalRef(env, vpnWrapper);

    psp_tunnel_start_args args = { 0 };
    args.bundle = cBundle;
    args.constants = cConstants;
    args.preferences = NULL;
    args.cache_dir = cCacheDir;
    args.profile = cProfile;
    args.is_interactive = true;
    args.is_daemon = false;
    args.jni_wrapper = jniVPNWrapper;
    // FIXME: #1700, C ABI, completion can inform about start errors
    const bool ret = psp_tunnel_start(&args, NULL);
    (*env)->ReleaseStringUTFChars(env, bundle, cBundle);
    (*env)->ReleaseStringUTFChars(env, constants, cConstants);
    (*env)->ReleaseStringUTFChars(env, profile, cProfile);
    (*env)->ReleaseStringUTFChars(env, cacheDir, cCacheDir);
    return ret;
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_NativeLibraryWrapper_daemonStop(JNIEnv *env, jobject thiz) {
    psp_tunnel_stop(NULL);
}
