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

typedef struct {
    void *event_ctx;
    jobject event_cb; // Global ref to Kotlin callback
} abi_event_handler;
void abi_event_callback_proxy(void *ctx, const char *event_json);

typedef struct {
    void *status_ctx;
    jobject status_cb; // Global ref to Kotlin callback
} connection_status_handler;
void connection_status_callback_proxy(void *ctx, const char *status_json);
