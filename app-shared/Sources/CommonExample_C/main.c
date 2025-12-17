/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <stdio.h>
#include "passepartout.h"

int main() {
    psp_init_args args = { 0 };
    printf("Hello Partout %s\n", psp_partout_version());
    args.cache_dir = ".";
    args.event_ctx = NULL;
    args.event_cb = NULL;
    psp_init(&args);
    return 0;
}
