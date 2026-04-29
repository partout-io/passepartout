/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <jni.h>
#include <assert.h>
#include <stdbool.h>
#include <stdlib.h>
#include "helpers.h"

// WARNING: Defining jvm is a requirement for Partout!
JavaVM *jvm = NULL;
JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    jvm = vm;
    return JNI_VERSION_1_6;
}

static
JNIEnv *jni_attach_thread(bool *did_attach) {
    JNIEnv *env;
    jint status = (*jvm)->GetEnv(jvm, (void **)&env, JNI_VERSION_1_6);
    switch (status) {
        case JNI_OK:
            *did_attach = false;
            return env;
        case JNI_EDETACHED:
            status = (*jvm)->AttachCurrentThread(jvm, &env, NULL);
            if (status != JNI_OK) return NULL;
            *did_attach = true;
            return env;
        default:
            return NULL;
    }
}

typedef struct {
    jobject ref;
} abi_handler;

void *abi_handler_create(JNIEnv *env, jobject ref) {
    abi_handler *handler = malloc(sizeof(abi_handler));
    handler->ref = (*env)->NewGlobalRef(env, ref);
    return handler;
}

static
void abi_handler_free(JNIEnv *env, abi_handler *handler) {
    if (!handler) return;
    (*env)->DeleteGlobalRef(env, handler->ref);
    free(handler);
}

/* Global */

void abi_handler_proxy(void *ctx, const char *method_id, const char *json) {
    assert(ctx);
    assert(method_id);
    assert(json);

    bool did_attach;
    JNIEnv *env = jni_attach_thread(&did_attach);
    if (!env) return;

    abi_handler *handler = (abi_handler *)ctx;
    jclass cls = (*env)->GetObjectClass(env, handler->ref);
    if (cls) {
        jmethodID methodID = (*env)->GetMethodID(env, cls, method_id,
                                                 "(Ljava/lang/String;)V");
        if (methodID) {
            jstring jeventJSON = (*env)->NewStringUTF(env, json);
            (*env)->CallVoidMethod(env, handler->ref, methodID, jeventJSON);
            (*env)->DeleteLocalRef(env, jeventJSON);
        }
        (*env)->DeleteLocalRef(env, cls);
    }
    if (did_attach) (*jvm)->DetachCurrentThread(jvm);
}

void abi_event_handler_proxy(void *ctx, const char *event_json) {
    abi_handler_proxy(ctx, "onEvent", event_json);
}

void abi_connection_status_handler_proxy(void *ctx, const char *status_json) {
    abi_handler_proxy(ctx, "onStatus", status_json);
}

/* Completion (fire and release) */

void abi_completion_proxy(void *ctx, int code, const char *json) {
    assert(ctx);

    bool did_attach;
    JNIEnv *env = jni_attach_thread(&did_attach);
    if (!env) return;

    abi_handler *handler = (abi_handler *)ctx;
    jclass cls = (*env)->GetObjectClass(env, handler->ref);
    if (cls) {
        jmethodID methodID = (*env)->GetMethodID(env, cls, "onComplete", "(ILjava/lang/String;)V");
        if (methodID) {
            jstring jJSON = json ? (*env)->NewStringUTF(env, json) : NULL;
            (*env)->CallVoidMethod(env, handler->ref, methodID, code, jJSON);
            if (jJSON) (*env)->DeleteLocalRef(env, jJSON);
        }
        (*env)->DeleteLocalRef(env, cls);
    }

    // Release handler on completion
    abi_handler_free(env, handler);

    if (did_attach) (*jvm)->DetachCurrentThread(jvm);
}
