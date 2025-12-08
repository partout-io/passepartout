/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#ifndef __PASSEPARTOUT_H
#define __PASSEPARTOUT_H

#include <stdbool.h>

const char *psp_partout_version();
bool psp_init();
void psp_deinit();

int psp_example_sum(int a, int b);
const char *psp_example_json();

#endif
