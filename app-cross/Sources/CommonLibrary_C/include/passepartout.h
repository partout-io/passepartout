/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#ifndef __PASSEPARTOUT_H
#define __PASSEPARTOUT_H

#include <stdbool.h>
#include <stdlib.h>

/* Common functions. */
const char *psp_partout_version(void);
void psp_log(const char *msg);
char *psp_readfile(const char *rel_path, const char *parent);

/* Events callback. */
typedef void (*psp_event_callback)(void *event_ctx, const char *event);

/* Completion callback.
 * - Success: code == 0, data = JSON (optional)
 * - Error:   code != 0, data = String
 */
#define PSPCompletionCodeOK         0
#define PSPCompletionCodeArgs       -2
#define PSPCompletionCodeFailure    -1
typedef void (*psp_completion_cb)(void *ctx, int code, const char *data);
typedef struct {
    void *ctx;
    psp_completion_cb callback;
} psp_completion;

/* Macros for completion blocks. */
static inline
psp_completion PSP_CB(void *ctx, psp_completion_cb callback) {
    psp_completion completion = { ctx, callback };
    return completion;
}
#define PSP_CB_NOP() PSP_CB(NULL, NULL)

typedef struct {
    void *event_ctx;
    psp_event_callback event_cb;
} psp_app_bindings;

typedef struct {
    void *controller;
    void *status_ctx;
    psp_event_callback status_cb;
} psp_tunnel_bindings;

/* App initialization. */
typedef struct {
    const char *bundle;
    const char *constants;
    const char *preferences;
    const char *profiles_dir;
    const char *cache_dir;
    psp_app_bindings bindings;
} psp_app_init_args;

/* App functions. */
void psp_app_init(const psp_app_init_args *args, psp_completion completion);
void psp_app_deinit(psp_completion completion);
void psp_app_on_foreground(void);
void psp_app_import_profile_path(const char *path, psp_completion completion);
void psp_app_import_profile_text(const char *text, const char *filename, psp_completion completion);
void psp_app_delete_profile(const char *uuid, psp_completion completion);
void psp_app_delete_profiles(const char **uuids, size_t num, psp_completion completion);
void psp_app_flush_log(void);

/* Daemon initialization. */
typedef struct {
    const char *bundle;
    const char *constants;
    const char *preferences;
    const char *cache_dir;
    const char *profile;
    bool is_interactive;
    bool is_daemon;
    psp_tunnel_bindings bindings;
} psp_tunnel_start_args;

/* Daemon functions. */
void psp_tunnel_start(const psp_tunnel_start_args *args, psp_completion completion);
void psp_tunnel_stop(psp_completion completion);

#endif
