/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#pragma once
#include <jni.h>

void *abi_handler_create(JNIEnv *env, jobject ref);

/* Global handlers (lifescope = application). */
void abi_event_handler_proxy(void *ctx, const char *event_json);
void abi_connection_status_handler_proxy(void *ctx, const char *status_json);

/* Completion handlers (lifescope = function call, released on call). */
void abi_completion_proxy(void *ctx, int code, const char *json);
