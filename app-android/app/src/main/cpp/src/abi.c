/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <jni.h>
#include <stdlib.h>
#include "abi.h"

JavaVM *g_vm = NULL;

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    g_vm = vm;
    return JNI_VERSION_1_6;
}

void abi_event_callback_proxy(const void *ctx, const char *event_json) {
    JNIEnv *env;
    (*g_vm)->AttachCurrentThread(g_vm, (void **)&env, NULL);

    abi_event_handler *handler = (abi_event_handler *)ctx;
    jclass cls = (*env)->GetObjectClass(env, handler->event_cb);
    jmethodID methodID = (*env)->GetMethodID(env, cls, "onEvent", "(Ljava/lang/Object;Ljava/lang/String;)V");
    jstring jeventJSON = (*env)->NewStringUTF(env, event_json);
    (*env)->CallVoidMethod(env, handler->event_cb, methodID, handler->event_ctx, jeventJSON);
    (*env)->DeleteLocalRef(env, jeventJSON);
    (*env)->DeleteLocalRef(env, cls);
}