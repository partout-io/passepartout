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

#define PSP_JNI_CB(e, c) PSP_CB(abi_handler_create(e, c), abi_completion_proxy)

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
    psp_app_init(&args, PSP_JNI_CB(env, completion));

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
    psp_app_deinit(PSP_JNI_CB(env, completion));
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_appRelease(
        JNIEnv *env,
        jobject thiz
) {
    if (app_references.eventHandler) {
        abi_handler_free(env, app_references.eventHandler);
        app_references.eventHandler = NULL;
    }
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
    psp_app_import_profile_text(cText, cName, PSP_JNI_CB(env, completion));
    (*env)->ReleaseStringUTFChars(env, text, cText);
    (*env)->ReleaseStringUTFChars(env, name, cName);
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_appDeleteProfile(
        JNIEnv *env,
        jobject thiz,
        jstring id,
        jobject completion
) {
    const char *cID = (*env)->GetStringUTFChars(env, id, NULL);
    psp_app_delete_profile(cID, PSP_JNI_CB(env, completion));
    (*env)->ReleaseStringUTFChars(env, id, cID);
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_appDeleteProfiles(
        JNIEnv *env,
        jobject thiz,
        jobjectArray ids,
        jobject completion
) {
    jni_string_array *ja = jni_string_array_create(env, ids);
    psp_app_delete_profiles(ja->cs, ja->count, PSP_JNI_CB(env, completion));
    jni_string_array_free(env, ja);
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

    psp_tunnel_start(&args, PSP_JNI_CB(env, completion));

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
    psp_tunnel_stop(PSP_JNI_CB(env, completion));
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_helpers_NativeLibraryWrapper_tunnelRelease(
        JNIEnv *env,
        jobject thiz
) {
    if (tunnel_references.jniController) {
        (*env)->DeleteGlobalRef(env, tunnel_references.jniController);
        tunnel_references.jniController = NULL;
    }
    if (tunnel_references.statusHandler) {
        abi_handler_free(env, tunnel_references.statusHandler);
        tunnel_references.statusHandler = NULL;
    }
}
