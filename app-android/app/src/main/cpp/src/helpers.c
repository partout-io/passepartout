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

/* Completion (fire and release) */

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

void abi_completion_proxy(void *ctx, int code, const char *json) {
    assert(ctx);
    JNI_ATTACH_OR_RETURN_VOID(env);

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

    JNI_DETACH(env);
}

/* JNI */

// WARNING: Defining jvm is a requirement for Partout!
JavaVM *jvm = NULL;

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)reserved;
    jvm = vm;
    return JNI_VERSION_1_6;
}

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
