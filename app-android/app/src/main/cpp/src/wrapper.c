/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <jni.h>
#include <stdlib.h>
#include "partout.h"
#include "helpers.h"

#define PARTOUT_JNI_CB(e, c) PARTOUT_CB(abi_completion_proxy, abi_handler_create(e, c))
static void daemon_bindings_free(partout_daemon_bindings *b);

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_PassepartoutWrapper_partoutInit(
        JNIEnv *env,
        jobject thiz,
        jstring tag,
        jboolean logs_private_data
) {
    (void)thiz;
    partout_init_args args = { 0 };
    const char *cTag = (*env)->GetStringUTFChars(env, tag, NULL);
    args.log_tag = cTag;
    args.logs_private_data = logs_private_data;
    partout_init(&args);
    (*env)->ReleaseStringUTFChars(env, tag, cTag);
}

JNIEXPORT jstring JNICALL
Java_com_algoritmico_passepartout_PassepartoutWrapper_partoutVersion(JNIEnv *env, jobject thiz) {
    (void)thiz;
    jstring jmsg = (*env)->NewStringUTF(env, partout_version());
    return jmsg;
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_PassepartoutWrapper_partoutImportProfile(
        JNIEnv *env,
        jobject thiz,
        jstring text,
        jstring name,
        jobject completion
) {
    (void)thiz;
    const char *cText = (*env)->GetStringUTFChars(env, text, NULL);
    const char *cName = name ? (*env)->GetStringUTFChars(env, name, NULL) : NULL;
    partout_import_profile(cText, cName, PARTOUT_JNI_CB(env, completion));
    (*env)->ReleaseStringUTFChars(env, text, cText);
    if (cName) (*env)->ReleaseStringUTFChars(env, name, cName);
}

JNIEXPORT jint JNICALL
Java_com_algoritmico_passepartout_PassepartoutWrapper_partoutDaemonStart(
        JNIEnv *env,
        jobject thiz,
        jstring profile,
        jstring cacheDir,
        jobject controller,
        jboolean logsSnapshots
) {
    (void)thiz;
    const char *cProfile = (*env)->GetStringUTFChars(env, profile, NULL);
    const char *cCacheDir = (*env)->GetStringUTFChars(env, cacheDir, NULL);

    partout_daemon_bindings bindings = { 0 };
    bindings.controller = (*env)->NewGlobalRef(env, controller);
    bindings.free = daemon_bindings_free;

    partout_daemon_start_args args = { 0 };
    args.cache_dir = cCacheDir;
    args.profile = cProfile;
    args.is_daemon = false;
    args.logs_snapshots = logsSnapshots;
    args.bindings = &bindings;
    const jint result = partout_daemon_start(&args);

    (*env)->ReleaseStringUTFChars(env, profile, cProfile);
    (*env)->ReleaseStringUTFChars(env, cacheDir, cCacheDir);
    return result;
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_PassepartoutWrapper_partoutDaemonStop(
        JNIEnv *env,
        jobject thiz,
        jobject completion
) {
    (void)thiz;
    partout_daemon_stop(PARTOUT_JNI_CB(env, completion));
}

void daemon_bindings_free(partout_daemon_bindings *b) {
    JNI_ATTACH_OR_RETURN_VOID(env);
    if (b->controller) {
        (*env)->DeleteGlobalRef(env, b->controller);
        b->controller = NULL;
    }
    JNI_DETACH(env);
}
