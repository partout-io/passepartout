/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <jni.h>
#include <stdlib.h>
#include "passepartout.h"
#include "helpers.h"

struct {
    abi_handler *eventHandler;
} app_references;

struct {
    jobject jniController;
    abi_handler *statusHandler;
} tunnel_references;

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
        jobject eventHandler,
        jobject completion
) {
    const char *cBundle = (*env)->GetStringUTFChars(env, bundle, NULL);
    const char *cConstants = (*env)->GetStringUTFChars(env, constants, NULL);
    const char *cProfilesDir = (*env)->GetStringUTFChars(env, profilesDir, NULL);
    const char *cCacheDir = (*env)->GetStringUTFChars(env, cacheDir, NULL);

    // Store globally
    app_references.eventHandler = abi_handler_create(env, eventHandler);

    psp_app_init_args args = { 0 };
    args.bundle = cBundle;
    args.constants = cConstants;
    args.preferences = "{\"logsPrivateData\": true}";
    args.profiles_dir = cProfilesDir;
    args.cache_dir = cCacheDir;
    args.bindings.event_ctx = app_references.eventHandler;
    args.bindings.event_cb = abi_event_handler_proxy;
    psp_app_init(&args, abi_handler_create(env, completion), abi_completion_proxy);

    (*env)->ReleaseStringUTFChars(env, bundle, cBundle);
    (*env)->ReleaseStringUTFChars(env, constants, cConstants);
    (*env)->ReleaseStringUTFChars(env, profilesDir, cProfilesDir);
    (*env)->ReleaseStringUTFChars(env, cacheDir, cCacheDir);
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_appDeinit(
        JNIEnv *env,
        jobject thiz,
        jobject completion
) {
    psp_app_deinit(abi_handler_create(env, completion), abi_completion_proxy);
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_appRelease(
        JNIEnv *env,
        jobject thiz
) {
    abi_handler_free(env, app_references.eventHandler);
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
        jobject controller,
        jobject completion
) {
    const char *cBundle = (*env)->GetStringUTFChars(env, bundle, NULL);
    const char *cConstants = (*env)->GetStringUTFChars(env, constants, NULL);
    const char *cProfile = (*env)->GetStringUTFChars(env, profile, NULL);
    const char *cCacheDir = (*env)->GetStringUTFChars(env, cacheDir, NULL);

    // Store global JNI references (ownership is transferred)
    tunnel_references.jniController = (*env)->NewGlobalRef(env, controller);
    tunnel_references.statusHandler = abi_handler_create(env, statusHandler);

    psp_tunnel_start_args args = { 0 };
    args.bundle = cBundle;
    args.constants = cConstants;
    args.preferences = "{\"logsPrivateData\": true}";
    args.cache_dir = cCacheDir;
    args.profile = cProfile;
    args.is_interactive = true;
    args.is_daemon = false;
    args.bindings.controller = tunnel_references.jniController;
    args.bindings.status_ctx = tunnel_references.statusHandler;
    args.bindings.status_cb = abi_connection_status_handler_proxy;

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

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_tunnelRelease(
        JNIEnv *env,
        jobject thiz
) {
    (*env)->DeleteGlobalRef(env, tunnel_references.jniController);
    abi_handler_free(env, tunnel_references.statusHandler);
}
