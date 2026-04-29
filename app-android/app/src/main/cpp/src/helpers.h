/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#pragma once
#include <jni.h>

typedef struct {
    void *completion_ctx;
    jobject completion_cb; // Global ref to Kotlin callback
} abi_completion_handler;
void abi_completion_callback_proxy(void *ctx, int code, const char *error_msg);

void *abi_handler_create(JNIEnv *env, jobject ref);
void abi_event_handler_proxy(void *ctx, const char *event_json);
void abi_connection_status_handler_proxy(void *ctx, const char *status_json);
