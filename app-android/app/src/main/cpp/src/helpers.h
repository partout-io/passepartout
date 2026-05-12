/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#pragma once
#include <jni.h>
#include <stdbool.h>

typedef struct {
    jobject ref;
} abi_handler;

abi_handler *abi_handler_create(JNIEnv *env, jobject ref);
void abi_handler_free(JNIEnv *env, abi_handler *handler);

/* Global handlers (lifescope = application). */
void abi_event_handler_proxy(void *ctx, const char *event_json);
void abi_connection_status_handler_proxy(void *ctx, const char *status_json);

/* Completion handlers (lifescope = function call, released on call). */
void abi_completion_proxy(void *ctx, int code, const char *json);

/* JNI helpers. */

typedef struct {
    const char **cs;
    jstring *js;
    jsize count;
} jni_string_array;
jni_string_array *jni_string_array_create(JNIEnv *env, jobjectArray v);
void jni_string_array_free(JNIEnv *env, jni_string_array *ja);

extern JavaVM *jvm;
JNIEnv *jni_attach_thread(bool *did_attach);

#define JNI_ATTACH_OR_RETURN(env_name, return_value) \
    bool env_name##_did_attach; \
    JNIEnv *env_name = jni_attach_thread(&env_name##_did_attach); \
    if (!(env_name)) return return_value

#define JNI_ATTACH_OR_RETURN_VOID(env_name) \
    bool env_name##_did_attach; \
    JNIEnv *env_name = jni_attach_thread(&env_name##_did_attach); \
    if (!(env_name)) return

#define JNI_ATTACH_OR_COMPLETE(env_name, completion, ctx) \
    bool env_name##_did_attach; \
    JNIEnv *env_name = jni_attach_thread(&env_name##_did_attach); \
    if (!(env_name)) { \
        if (completion) completion(ctx, -1); \
        return; \
    }

#define JNI_DETACH(env_name) \
    do { \
        if (env_name##_did_attach) (*jvm)->DetachCurrentThread(jvm); \
    } while (0)
