/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <jni.h>
#include <stdlib.h>
#include "passepartout.h"
#include "helpers.h"

#define PSP_JNI_CB(e, c) PSP_CB(abi_handler_create(e, c), abi_completion_proxy)
static void app_bindings_free(psp_app_bindings *b);
static void tunnel_bindings_free(psp_tunnel_bindings *b);

JNIEXPORT jstring JNICALL
Java_com_algoritmico_passepartout_abi_PassepartoutWrapper_partoutVersion(JNIEnv *env, jobject thiz) {
    jstring jmsg = (*env)->NewStringUTF(env, psp_partout_version());
    return jmsg;
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_abi_PassepartoutWrapper_appOnForeground(JNIEnv *env, jobject thiz) {
    psp_app_on_foreground();
}

JNIEXPORT jint JNICALL
Java_com_algoritmico_passepartout_abi_PassepartoutWrapper_appInit(
        JNIEnv *env,
        jobject thiz,
        jstring bundle,
        jstring constants,
        jstring preferences,
        jstring profilesDir,
        jstring cacheDir,
        jobject urlFetcher,
        jobject eventHandler
) {
    const char *cBundle = (*env)->GetStringUTFChars(env, bundle, NULL);
    const char *cConstants = (*env)->GetStringUTFChars(env, constants, NULL);
    const char *cPreferences = preferences ? (*env)->GetStringUTFChars(env, preferences, NULL) : NULL;
    const char *cProfilesDir = (*env)->GetStringUTFChars(env, profilesDir, NULL);
    const char *cCacheDir = (*env)->GetStringUTFChars(env, cacheDir, NULL);

    psp_app_bindings bindings = { 0 };
    bindings.event_ctx = abi_handler_create(env, eventHandler);
    bindings.event_cb = abi_event_handler_proxy;
    bindings.request_ctx = abi_handler_create(env, urlFetcher);
    bindings.request_cb = abi_request_handler_proxy;
    bindings.free = app_bindings_free;

    psp_app_init_args args = { 0 };
    args.bundle = cBundle;
    args.constants = cConstants;
    args.preferences = cPreferences;
    args.profiles_dir = cProfilesDir;
    args.cache_dir = cCacheDir;
    args.bindings = bindings;
    const jint result = psp_app_init(&args);

    (*env)->ReleaseStringUTFChars(env, bundle, cBundle);
    (*env)->ReleaseStringUTFChars(env, constants, cConstants);
    if (cPreferences) (*env)->ReleaseStringUTFChars(env, preferences, cPreferences);
    (*env)->ReleaseStringUTFChars(env, profilesDir, cProfilesDir);
    (*env)->ReleaseStringUTFChars(env, cacheDir, cCacheDir);
    return result;
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_abi_PassepartoutWrapper_appDeinit(
        JNIEnv *env,
        jobject thiz,
        jobject completion
) {
    psp_app_deinit(PSP_JNI_CB(env, completion));
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_abi_PassepartoutWrapper_appImportProfileText(
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
Java_com_algoritmico_passepartout_abi_PassepartoutWrapper_appDeleteProfile(
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
Java_com_algoritmico_passepartout_abi_PassepartoutWrapper_appDeleteProfiles(
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
Java_com_algoritmico_passepartout_abi_PassepartoutWrapper_appFetchProfile(
        JNIEnv *env,
        jobject thiz,
        jstring id,
        jobject completion
) {
    const char *cID = (*env)->GetStringUTFChars(env, id, NULL);
    psp_app_fetch_profile(cID, PSP_JNI_CB(env, completion));
    (*env)->ReleaseStringUTFChars(env, id, cID);
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_abi_PassepartoutWrapper_appChangelog(
        JNIEnv *env, jobject thiz,
        jstring version,
        jobject completion
) {
    const char *cVersion = (*env)->GetStringUTFChars(env, version, NULL);
    psp_app_fetch_changelog(cVersion, PSP_JNI_CB(env, completion));
    (*env)->ReleaseStringUTFChars(env, version, cVersion);
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_abi_PassepartoutWrapper_appPreferencesSet(
        JNIEnv *env,
        jobject thiz,
        jstring preferences
) {
    const char *cPreferences = (*env)->GetStringUTFChars(env, preferences, NULL);
    psp_app_preferences_set(cPreferences);
    (*env)->ReleaseStringUTFChars(env, preferences, cPreferences);
}

JNIEXPORT jint JNICALL
Java_com_algoritmico_passepartout_abi_PassepartoutWrapper_tunnelStart(
        JNIEnv *env,
        jobject thiz,
        jstring bundle,
        jstring constants,
        jstring preferences,
        jstring profile,
        jstring cacheDir,
        jobject controller
) {
    const char *cBundle = (*env)->GetStringUTFChars(env, bundle, NULL);
    const char *cConstants = (*env)->GetStringUTFChars(env, constants, NULL);
    const char *cPreferences = preferences ? (*env)->GetStringUTFChars(env, preferences, NULL) : NULL;
    const char *cProfile = (*env)->GetStringUTFChars(env, profile, NULL);
    const char *cCacheDir = (*env)->GetStringUTFChars(env, cacheDir, NULL);

    psp_tunnel_bindings bindings = { 0 };
    bindings.controller = (*env)->NewGlobalRef(env, controller);
    bindings.free = tunnel_bindings_free;

    psp_tunnel_start_args args = { 0 };
    args.bundle = cBundle;
    args.constants = cConstants;
    args.preferences = cPreferences;
    args.cache_dir = cCacheDir;
    args.profile = cProfile;
    args.is_interactive = true;
    args.is_daemon = false;
    args.bindings = bindings;

    const jint result = psp_tunnel_start(&args);

    (*env)->ReleaseStringUTFChars(env, bundle, cBundle);
    (*env)->ReleaseStringUTFChars(env, constants, cConstants);
    if (cPreferences) (*env)->ReleaseStringUTFChars(env, preferences, cPreferences);
    (*env)->ReleaseStringUTFChars(env, profile, cProfile);
    (*env)->ReleaseStringUTFChars(env, cacheDir, cCacheDir);
    return result;
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_abi_PassepartoutWrapper_tunnelStop(
        JNIEnv *env,
        jobject thiz,
        jobject completion
) {
    psp_tunnel_stop(PSP_JNI_CB(env, completion));
}

void app_bindings_free(psp_app_bindings *b) {
    JNI_ATTACH_OR_RETURN_VOID(env);
    if (b->event_ctx) {
        abi_handler_free(env, b->event_ctx);
        b->event_ctx = NULL;
    }
    if (b->request_ctx) {
        abi_handler_free(env, b->request_ctx);
        b->request_ctx = NULL;
    }
    JNI_DETACH(env);
}

void tunnel_bindings_free(psp_tunnel_bindings *b) {
    JNI_ATTACH_OR_RETURN_VOID(env);
    if (b->controller) {
        (*env)->DeleteGlobalRef(env, b->controller);
        b->controller = NULL;
    }
    JNI_DETACH(env);
}
