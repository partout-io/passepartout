/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#pragma once
#include <jni.h>
#include <stdbool.h>

/* Completion handlers (lifescope = function call, released on call). */

typedef struct {
    jobject ref;
} abi_handler;

abi_handler *abi_handler_create(JNIEnv *env, jobject ref);
void abi_handler_free(JNIEnv *env, abi_handler *handler);
void abi_completion_proxy(void *ctx, int code, const char *json);

/* JNI helpers. */

extern JavaVM *jvm;
JNIEnv *jni_attach_thread(bool *did_attach);

#define JNI_ATTACH_OR_RETURN_VOID(env_name) \
    bool env_name##_did_attach; \
    JNIEnv *env_name = jni_attach_thread(&env_name##_did_attach); \
    if (!(env_name)) return

#define JNI_DETACH(env_name) \
    do { \
        if (env_name##_did_attach) (*jvm)->DetachCurrentThread(jvm); \
    } while (0)
