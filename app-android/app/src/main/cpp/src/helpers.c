/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
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
    JNIEnv *env;
    (*jvm)->AttachCurrentThread(jvm, &env, NULL);

    assert(ctx);

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

void abi_event_callback_proxy(void *ctx, const char *event_json) {
    JNIEnv *env;
    (*jvm)->AttachCurrentThread(jvm, &env, NULL);

    assert(ctx);
    assert(event_json);
    abi_event_handler *handler = (abi_event_handler *)ctx;
    jclass cls = (*env)->GetObjectClass(env, handler->event_cb);
    if (cls) {
        jmethodID methodID = (*env)->GetMethodID(env, cls, "onEvent",
                                                 "(Ljava/lang/Object;Ljava/lang/String;)V");
        if (methodID) {
            jstring jeventJSON = (*env)->NewStringUTF(env, event_json);
            (*env)->CallVoidMethod(env, handler->event_cb, methodID, handler->event_ctx,
                                   jeventJSON);
            (*env)->DeleteLocalRef(env, jeventJSON);
        }
        (*env)->DeleteLocalRef(env, cls);
    }

    (*jvm)->DetachCurrentThread(jvm);
}