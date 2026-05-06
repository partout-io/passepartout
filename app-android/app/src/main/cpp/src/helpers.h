/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#pragma once
#include <jni.h>

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

/* Type helpers. */
typedef struct {
    const char **cs;
    jstring *js;
    jsize count;
} jni_string_array;
jni_string_array *jni_string_array_create(JNIEnv *env, jobjectArray v);
void jni_string_array_free(JNIEnv *env, jni_string_array *ja);
