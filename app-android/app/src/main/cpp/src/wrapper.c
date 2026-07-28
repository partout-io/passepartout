/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <jni.h>
#include <stdlib.h>
#include <android/log.h>
#include "partout.h"
#include "helpers.h"

#define PARTOUT_JNI_CB(e, c) PARTOUT_CB(abi_completion_proxy, abi_handler_create(e, c))
static void daemon_bindings_free(partout_daemon_bindings *b);

static void partout_log(int level, const char *message) {
    int android_level = 0;
    switch (level) {
        case PartoutLogLevelDebug:
            android_level = ANDROID_LOG_VERBOSE;
            break;
        case PartoutLogLevelInfo:
            android_level = ANDROID_LOG_DEBUG;
            break;
        case PartoutLogLevelNotice:
            android_level = ANDROID_LOG_INFO;
            break;
        case PartoutLogLevelError:
            android_level = ANDROID_LOG_WARN;
            break;
        case PartoutLogLevelFault:
            android_level = ANDROID_LOG_FATAL;
            break;
    }
    __android_log_print(android_level, "Partout", "%s", message);
}

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
    args.logs_private_data = logs_private_data;
    args.logger = partout_log;
    partout_init(&args);
    (*env)->ReleaseStringUTFChars(env, tag, cTag);
}

JNIEXPORT jstring JNICALL
Java_com_algoritmico_passepartout_PassepartoutWrapper_partoutVersion(JNIEnv *env, jobject thiz) {
    (void)thiz;
    jstring jmsg = (*env)->NewStringUTF(env, partout_version());
    return jmsg;
}

JNIEXPORT jstring JNICALL
Java_com_algoritmico_passepartout_PassepartoutWrapper_partoutImportProfile(
        JNIEnv *env,
        jobject thiz,
        jstring text,
        jstring name
) {
    (void)thiz;
    const char *cText = (*env)->GetStringUTFChars(env, text, NULL);
    const char *cName = name ? (*env)->GetStringUTFChars(env, name, NULL) : NULL;
    char *json = partout_import_profile(cText, cName);
    (*env)->ReleaseStringUTFChars(env, text, cText);
    if (cName) (*env)->ReleaseStringUTFChars(env, name, cName);

    jstring jJSON = json ? (*env)->NewStringUTF(env, json) : NULL;
    free(json);
    return jJSON;
}

JNIEXPORT jint JNICALL
Java_com_algoritmico_passepartout_PassepartoutWrapper_partoutDaemonStart(
        JNIEnv *env,
        jobject thiz,
        jstring profile,
        jstring cacheDir,
        jobject controller,
        jlong minDataCountDelta
) {
    (void) thiz;
    const char *cProfile = (*env)->GetStringUTFChars(env, profile, NULL);
    const char *cCacheDir = (*env)->GetStringUTFChars(env, cacheDir, NULL);

    partout_daemon_bindings bindings = {0};
    bindings.controller = (*env)->NewGlobalRef(env, controller);
    bindings.release = daemon_bindings_free;

    partout_daemon_start_args args = {0};
    args.profile = cProfile;
    args.options.is_daemon = false;
    args.options.cache_dir = cCacheDir;
    args.options.min_data_count_delta = minDataCountDelta;
    args.bindings = &bindings;
    const jint result = partout_daemon_start(&args);

    (*env)->ReleaseStringUTFChars(env, profile, cProfile);
    (*env)->ReleaseStringUTFChars(env, cacheDir, cCacheDir);
    return result;
}

JNIEXPORT void JNICALL
Java_com_algoritmico_passepartout_PassepartoutWrapper_partoutDaemonStop(
        JNIEnv *env,
        jobject thiz
) {
    (void)env;
    (void)thiz;
    partout_daemon_stop();
}

void daemon_bindings_free(partout_daemon_bindings *b) {
    JNI_ATTACH_OR_RETURN_VOID(env);
    if (b->controller) {
        (*env)->DeleteGlobalRef(env, b->controller);
        b->controller = NULL;
    }
    JNI_DETACH(env);
}
