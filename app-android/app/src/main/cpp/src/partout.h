/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#ifndef __PARTOUT_H
#define __PARTOUT_H

#include <stdbool.h>
#include <stddef.h>

/*
 * Success -> int == 0 or != NULL
 * Failure -> int != 0 or == NULL
 */

extern const char *const PARTOUT_IDENTIFIER;
extern const char *const PARTOUT_VERSION;

typedef struct {
    const char *cache_dir;
    void (*test_callback)();
} partout_init_args;

void *partout_init(const partout_init_args *args);
void partout_deinit(void *ctx);

typedef struct {
    const int *remote_fds;
    size_t remote_fds_len;
} partout_tun_ctrl_info;

typedef struct {
    void *thiz;
    void *(*set_tunnel)(void *thiz, const partout_tun_ctrl_info *info);
    void (*configure_sockets)(void *thiz, const int *fds, size_t fds_len);
    void (*clear_tunnel)(void *thiz, void *tun_impl);
    void (*test_callback)(void *thiz);
} partout_tun_ctrl;

typedef struct {
    const char *profile;
    const char *profile_path;
    partout_tun_ctrl *ctrl;
} partout_daemon_start_args;

bool partout_daemon_start(void *ctx, const partout_daemon_start_args *args);
void partout_daemon_stop(void *ctx);

#endif
