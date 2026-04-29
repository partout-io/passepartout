/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <jni.h>
#include <assert.h>
#include <stdlib.h>
#include "helpers.h"

// WARNING: Defining jvm is a requirement for Partout!
JavaVM *jvm = NULL;
JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    jvm = vm;
    return JNI_VERSION_1_6;
}

void abi_completion_callback_proxy(void *ctx, int code, const char *error_msg) {
    assert(ctx);

    JNIEnv *env;
    (*jvm)->AttachCurrentThread(jvm, &env, NULL);
    abi_completion_handler *handler = (abi_completion_handler *)ctx;
    jclass cls = (*env)->GetObjectClass(env, handler->completion_cb);
    if (cls) {
        jmethodID methodID = (*env)->GetMethodID(env, cls, "onComplete",
                                                 "(Ljava/lang/Object;ILjava/lang/String;)V");
        if (methodID) {
            if (error_msg) {
                jstring jerrorMsg = (*env)->NewStringUTF(env, error_msg);
                (*env)->CallVoidMethod(env, handler->completion_cb, methodID,
                                       handler->completion_ctx, code, jerrorMsg);
                (*env)->DeleteLocalRef(env, jerrorMsg);
            } else {
                (*env)->CallVoidMethod(env, handler->completion_cb, methodID,
                                       handler->completion_ctx, code, NULL);
            }
        }
        (*env)->DeleteLocalRef(env, cls);
    }

    // Clean up JNI ref to completion callback
    (*env)->DeleteGlobalRef(env, handler->completion_cb);
    // Clean up temporary proxy handler
    free(handler);
    (*jvm)->DetachCurrentThread(jvm);
}

typedef struct {
    jobject ref;
} abi_handler;

void *abi_handler_create(JNIEnv *env, jobject ref) {
    abi_handler *handler = malloc(sizeof(abi_handler));
    handler->ref = (*env)->NewGlobalRef(env, ref);
    return handler;
}

void abi_handler_proxy(void *ctx, const char *method_id, const char *json) {
    assert(ctx);
    assert(json);

    JNIEnv *env;
    (*jvm)->AttachCurrentThread(jvm, &env, NULL);
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
    (*jvm)->DetachCurrentThread(jvm);
}

void abi_event_handler_proxy(void *ctx, const char *event_json) {
    abi_handler_proxy(ctx, "onEvent", event_json);
}

void abi_connection_status_handler_proxy(void *ctx, const char *status_json) {
    abi_handler_proxy(ctx, "onStatus", status_json);
}
