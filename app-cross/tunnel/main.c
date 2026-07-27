/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <stdio.h>
#include <stdlib.h>
#include "passepartout.h"

int main(int argc, char *argv[]) {
    char *bundle = NULL;
    char *constants = NULL;
    char *profile = NULL;

    printf("Passepartout Tunnel (%s)\n", psp_partout_version());
    if (argc <= 1) {
        fprintf(stderr, "Missing path to profile\n");
        return -1;
    }

#ifdef USE_SWIFTPM
    const char *parent = "app-cross_passepartout-shared.bundle/Contents/Resources/assets";
#else
    const char *parent = NULL;
#endif

    /* App bundle and constants ship as assets; the profile is a JSON path arg. */
    if ((bundle = psp_readfile("bundle.json", parent)) == NULL) {
        fprintf(stderr, "Unable to open bundle\n");
        goto failure;
    }
    if ((constants = psp_readfile("constants.json", parent)) == NULL) {
        fprintf(stderr, "Unable to open constants\n");
        goto failure;
    }
    if ((profile = psp_readfile(argv[1], NULL)) == NULL) {
        fprintf(stderr, "Unable to open profile: %s\n", argv[1]);
        goto failure;
    }

    /* FIXME: #209/notes, Cross UI, hardcoded cache dir */
    const char *cache_dir = ".";

    psp_tunnel_start_args args = {0};
    args.bundle = bundle;
    args.constants = constants;
    args.preferences = NULL;
    args.cache_dir = cache_dir;
    args.profile = profile;
    args.is_interactive = false;
    args.is_daemon = true;
    args.bindings.controller = NULL;
    args.bindings.free = NULL;

    /* Blocks indefinitely while the daemon runs. */
    const int result = psp_tunnel_start(&args);

    free(bundle);
    free(constants);
    free(profile);
    return result;
failure:
    if (bundle) free(bundle);
    if (constants) free(constants);
    if (profile) free(profile);
    return -1;
}
