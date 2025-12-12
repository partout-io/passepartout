/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#ifndef __PASSEPARTOUT_H
#define __PASSEPARTOUT_H

#include <stdbool.h>

const char *psp_partout_version();
void psp_init(const char *cache_dir);
void psp_deinit();
bool psp_daemon_start(const char *profile, void *jni_wrapper);
void psp_daemon_stop();

int psp_example_sum(int a, int b);

#endif
