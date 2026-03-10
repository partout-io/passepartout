/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#pragma once
#include <jni.h>

typedef struct {
    void *event_ctx;
    jobject event_cb; // Global ref to Kotlin callback
} abi_event_handler;
void abi_event_callback_proxy(const void *ctx, const char *event_json);
