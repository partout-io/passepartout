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

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_NativeLibraryWrapper_initialize(JNIEnv *env, jobject thiz, jstring cacheDir) {
    const char *cCacheDir = (*env)->GetStringUTFChars(env, cacheDir, NULL);
    psp_init(cCacheDir);
    (*env)->ReleaseStringUTFChars(env, cacheDir, cCacheDir);
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_NativeLibraryWrapper_deinitialize(JNIEnv *env, jobject thiz) {
    psp_deinit();
}

JNIEXPORT jboolean JNICALL
Java_com_algoritmico_passepartout_NativeLibraryWrapper_daemonStart(JNIEnv *env, jobject thiz, jstring profile, jobject vpnWrapper) {
    const char *cProfile = (*env)->GetStringUTFChars(env, profile, NULL);

    // Store global reference of builder wrapper
    jobject jniVPNWrapper = (*env)->NewGlobalRef(env, vpnWrapper);

    const bool ret = psp_daemon_start(cProfile, jniVPNWrapper);
    (*env)->ReleaseStringUTFChars(env, profile, cProfile);
    return ret;
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_NativeLibraryWrapper_daemonStop(JNIEnv *env, jobject thiz) {
    psp_daemon_stop();
}
