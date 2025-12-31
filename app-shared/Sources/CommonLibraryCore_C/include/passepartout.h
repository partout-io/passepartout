/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#ifndef __PASSEPARTOUT_H
#define __PASSEPARTOUT_H

#include <stdbool.h>

const char *psp_partout_version();
int psp_example_sum(int a, int b);

/* Common structures. */
//typedef const char *psp_id;
typedef const char *psp_json;
//psp_json psp_json_new(const char *);
//void psp_json_free(psp_json);

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

/* App initialization. */
typedef struct {
    const char *app_configuration;
    const char *profiles_dir;
    void *event_ctx;
    psp_event_callback event_cb;
} psp_app_init_args;
void psp_app_init(const psp_app_init_args *args);

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

/* Daemon initialization. */
typedef struct {
    const char *app_configuration;
    const char *cache_dir;
    const char *profile;
    bool is_interactive;
    void *jni_wrapper;
} psp_tunnel_start_args;
bool psp_tunnel_start(const psp_tunnel_start_args *args, void (*callback)(int));
void psp_tunnel_stop(void (*callback)());

#endif
