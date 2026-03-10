/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#ifndef __PASSEPARTOUT_ABI_H
#define __PASSEPARTOUT_ABI_H

#include <jni.h>

extern JavaVM *jvm;

typedef struct {
    void *event_ctx;
    jobject event_cb; // Global ref to Kotlin callback
} abi_event_handler;
void abi_event_callback_proxy(const void *ctx, const char *event_json);

#endif
