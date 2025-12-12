/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <stdio.h>
#include "passepartout.h"

int main() {
    printf("Hello Passepartout (Partout %s)\n", psp_partout_version());
    return 0;
}
