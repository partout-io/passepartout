/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <jni.h>
#include <stdlib.h>
#include "passepartout.h"
#include "helpers.h"

JNIEXPORT jstring JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_partoutVersion(JNIEnv *env, jobject thiz) {
    jstring jmsg = (*env)->NewStringUTF(env, psp_partout_version());
    return jmsg;
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_appOnForeground(JNIEnv *env, jobject thiz) {
    psp_app_on_foreground();
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_appInit(
        JNIEnv *env,
        jobject thiz,
        jstring bundle,
        jstring constants,
        jstring profilesDir,
        jstring cacheDir,
        jobject eventHandler) {
    const char *cBundle = (*env)->GetStringUTFChars(env, bundle, NULL);
    const char *cConstants = (*env)->GetStringUTFChars(env, constants, NULL);
    const char *cProfilesDir = (*env)->GetStringUTFChars(env, profilesDir, NULL);
    const char *cCacheDir = (*env)->GetStringUTFChars(env, cacheDir, NULL);

    psp_app_init_args args = { 0 };
    args.bundle = cBundle;
    args.constants = cConstants;
    args.preferences = "{\"logsPrivateData\": true}";
    args.profiles_dir = cProfilesDir;
    args.cache_dir = cCacheDir;
    args.event_ctx = abi_handler_create(env, eventHandler);
    args.event_cb = abi_event_handler_proxy;
    psp_app_init(&args);

    (*env)->ReleaseStringUTFChars(env, bundle, cBundle);
    (*env)->ReleaseStringUTFChars(env, constants, cConstants);
    (*env)->ReleaseStringUTFChars(env, profilesDir, cProfilesDir);
    (*env)->ReleaseStringUTFChars(env, cacheDir, cCacheDir);
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_appImportProfileText(
        JNIEnv *env,
        jobject thiz,
        jstring text,
        jstring name,
        jobject completion
) {
    const char *cText = (*env)->GetStringUTFChars(env, text, NULL);
    const char *cName = (*env)->GetStringUTFChars(env, name, NULL);
    void *handler = abi_handler_create(env, completion);
    psp_app_import_profile_text(cText, cName, handler, abi_completion_proxy);
    (*env)->ReleaseStringUTFChars(env, text, cText);
    (*env)->ReleaseStringUTFChars(env, name, cName);
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_tunnelStart(
        JNIEnv *env,
        jobject thiz,
        jstring bundle,
        jstring constants,
        jstring profile,
        jstring cacheDir,
        jobject statusHandler,
        jobject vpnWrapper,
        jobject completion
) {
    const char *cBundle = (*env)->GetStringUTFChars(env, bundle, NULL);
    const char *cConstants = (*env)->GetStringUTFChars(env, constants, NULL);
    const char *cProfile = (*env)->GetStringUTFChars(env, profile, NULL);
    const char *cCacheDir = (*env)->GetStringUTFChars(env, cacheDir, NULL);

    // Store global reference of builder wrapper
    jobject jniVPNWrapper = (*env)->NewGlobalRef(env, vpnWrapper);

    psp_tunnel_start_args args = { 0 };
    args.bundle = cBundle;
    args.constants = cConstants;
    args.preferences = "{\"logsPrivateData\": true}";
    args.cache_dir = cCacheDir;
    args.profile = cProfile;
    args.is_interactive = true;
    args.is_daemon = false;
    args.status_ctx = abi_handler_create(env, statusHandler);
    args.status_cb = abi_connection_status_handler_proxy;
    args.jni_wrapper = jniVPNWrapper;

    void *handler = abi_handler_create(env, completion);
    psp_tunnel_start(&args, handler, abi_completion_proxy);

    (*env)->ReleaseStringUTFChars(env, bundle, cBundle);
    (*env)->ReleaseStringUTFChars(env, constants, cConstants);
    (*env)->ReleaseStringUTFChars(env, profile, cProfile);
    (*env)->ReleaseStringUTFChars(env, cacheDir, cCacheDir);
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_tunnelStop(
        JNIEnv *env,
        jobject thiz,
        jobject completion
) {
    void *handler = abi_handler_create(env, completion);
    psp_tunnel_stop(handler, abi_completion_proxy);
}
