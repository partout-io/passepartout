/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#ifndef __PASSEPARTOUT_H
#define __PASSEPARTOUT_H

#include <stdbool.h>

/* Common functions. */
const char *psp_partout_version(void);
char *psp_readfile(const char *rel_path, const char *parent);

/* Events callback. */
typedef void (*psp_event_callback)(const void *event_ctx, const char *event);

/* Completion callbacks. */
/* Success: code == 0. */
typedef void (*psp_abi_cb_error)(void *ctx, int code, const char *error_message);
typedef void (*psp_abi_cb_void)(void *ctx);

/* App initialization. */
typedef struct {
    const char *bundle;
    const char *constants;
    const char *preferences;
    const char *profiles_dir;
    const char *cache_dir;
    void *event_ctx;
    psp_event_callback event_cb;
} psp_app_init_args;

/* App functions. */
void psp_app_init(const psp_app_init_args *args);
void psp_app_on_foreground();
void psp_app_import_profile(const char *path, void *ctx, psp_abi_cb_error completion);
void psp_app_flush_log();

/* Options. */
//typedef enum {
//    PSPOptionDNSFallsBack,
//    PSPOptionLogsPrivateData,
//    PSPOptionSkipsPurchases
//} psp_option;
//void psp_option_set_bool(psp_option, bool);
//void psp_option_set_int(psp_option, int);
//void psp_option_set_string(psp_option, const char *);
//void psp_option_set_object(psp_option, const psp_json *);

/* Daemon initialization. */
typedef struct {
    const char *bundle;
    const char *constants;
    const char *preferences;
    const char *cache_dir;
    const char *profile;
    bool is_interactive;
    bool is_daemon;
    void *jni_wrapper;
} psp_tunnel_start_args;

/* Daemon functions. */
bool psp_tunnel_start(const psp_tunnel_start_args *args, void *ctx, psp_abi_cb_error callback);
void psp_tunnel_stop(void *ctx, psp_abi_cb_void callback);

#endif
