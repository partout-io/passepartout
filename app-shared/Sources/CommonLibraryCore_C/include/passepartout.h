/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#ifndef __PASSEPARTOUT_H
#define __PASSEPARTOUT_H

#include <stdbool.h>

/* Common structures. */
typedef const char *psp_id;
typedef const char *psp_json;
psp_json psp_json_new(const char *);
void psp_json_free(psp_json);

/* Errors. */
//typedef enum {
//    PSPErrorNone,
//    PSPErrorSome
//} psp_error;
//typedef void (*psp_completion)(psp_error, psp_json);
//const char *psp_last_error();

/* Events. */
typedef enum {
    PSPAreaProfile = 1,
    PSPAreaTunnel = 2
} psp_area;
typedef enum {
    PSPEventTypeNone,
    PSPEventTypeProfileReady,
    PSPEventTypeProfileLocal,
    PSPEventTypeProfileRemote,
    PSPEventTypeProfileRequiredFeatures
} psp_event_type;
typedef struct {
    psp_area area;
    psp_event_type type;
    const psp_json *object;
} psp_event;
typedef void (*psp_event_callback)(void *event_ctx, const psp_event *event);

/* Initialization. */
typedef struct {
    const char *cache_dir;
    void *event_ctx;
    psp_event_callback event_cb;
} psp_init_args;
const char *psp_partout_version();
void psp_init(const psp_init_args *args);
void psp_deinit();

///* Profiles. */
//psp_json psp_profile_get_headers();
//void psp_profile_new(psp_completion);
//void psp_profile_import_text(psp_json, psp_completion);
//void psp_profile_update(psp_json, psp_completion);
//void psp_profile_dup(psp_id, psp_completion);
//void psp_profile_delete(psp_id, psp_completion);
//
///* Tunnel */
//psp_json psp_tunnel_get_all();
//void psp_tunnel_set_enabled(psp_id, bool);

/* Tunnel daemon. */
bool psp_daemon_start(const char *profile, void *jni_wrapper);
void psp_daemon_stop();

int psp_example_sum(int a, int b);

#endif
