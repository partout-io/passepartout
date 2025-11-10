/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#ifndef __PASSEPARTOUT_H
#define __PASSEPARTOUT_H

#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>

/* Common structures. */
typedef const char *psp_id;
typedef const char *psp_json;
psp_json psp_json_new(const char *);
void psp_json_free(psp_json);

/* Errors. */
typedef enum {
    PSPErrorNone,
    PSPErrorSome
} psp_error;
typedef void (*psp_completion)(psp_error, psp_json);
const char *psp_last_error();

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
    const void *object; // FIXME: ###, use psp_json here (optional)
} psp_event;
typedef void (*psp_event_callback)(void *, psp_event);

/* Initialization. */
void psp_initialize(void *, psp_event_callback);

/* Profiles. */
psp_json psp_profile_get_headers();
void psp_profile_new(psp_completion);
void psp_profile_import_text(psp_json, psp_completion);
void psp_profile_update(psp_json, psp_completion);
void psp_profile_dup(psp_id, psp_completion);
void psp_profile_delete(psp_id, psp_completion);

/* Tunnel */
psp_json psp_tunnel_get_all();
void psp_tunnel_set_enabled(psp_id, bool);

#endif
