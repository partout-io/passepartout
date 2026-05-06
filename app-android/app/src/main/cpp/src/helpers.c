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

abi_handler *abi_handler_create(JNIEnv *env, jobject ref) {
    abi_handler *handler = malloc(sizeof(abi_handler));
    handler->ref = (*env)->NewGlobalRef(env, ref);
    return handler;
}

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

/* Types */

jni_string_array *jni_string_array_create(JNIEnv *env, jobjectArray v) {
    if (env == NULL || v == NULL) return NULL;
    const char **cs = NULL;
    jstring *js = NULL;
    const jsize count = (*env)->GetArrayLength(env, v);
    cs = calloc(count > 0 ? count : 1, sizeof(*cs));
    if (!cs) goto failure;
    js = calloc(count > 0 ? count : 1, sizeof(*js));
    if (!js) goto failure;
    for (jsize i = 0; i < count; i++) {
        js[i] = (jstring) (*env)->GetObjectArrayElement(env, v, i);
        cs[i] = (*env)->GetStringUTFChars(env, js[i], NULL);
    }
    jni_string_array *ja = (jni_string_array *) malloc(sizeof(*ja));
    ja->cs = cs;
    ja->js = js;
    ja->count = count;
    return ja;
failure:
    if (cs) free(cs);
    if (js) free(js);
    return NULL;
}

void jni_string_array_free(JNIEnv *env, jni_string_array *ja) {
    if (!ja) return;
    for (jsize i = 0; i < ja->count; i++) {
        (*env)->ReleaseStringUTFChars(env, ja->js[i], ja->cs[i]);
        (*env)->DeleteLocalRef(env, ja->js[i]);
    }
    free(ja->js);
    free(ja->cs);
    free(ja);
}
