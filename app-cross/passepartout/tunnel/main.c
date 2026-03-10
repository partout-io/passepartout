/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <stdio.h>
#include <stdlib.h>
#include "passepartout.h"

static
void start_callback(void *ctx, int result, const char *error) {
    (void)ctx;
    if (error) {
        printf("Result: %d, %s\n", result, error);
    } else {
        printf("Result: %d\n", result);
    }
}

int main(int argc, char *argv[]) {
    char *bundle = NULL;
    char *constants = NULL;
    char *profile = NULL;

    printf("Passepartout Tunnel (Partout: %s)\n", psp_partout_version());
    if (argc <= 3) {
        fprintf(stderr, "Missing path to bundle, constants, profile\n");
        return -1;
    }

#ifdef USE_SWIFTPM
    const char *parent = "app-cross_passepartout-shared.bundle/Contents/Resources/assets";
#else
    const char *parent = NULL;
#endif

    /* Paths to JSON input. */
    if ((bundle = psp_readfile(argv[1], parent)) == NULL) {
        fprintf(stderr, "Unable to open bundle: %s\n", argv[1]);
        goto failure;
    }
    if ((constants = psp_readfile(argv[2], parent)) == NULL) {
        fprintf(stderr, "Unable to open constants: %s\n", argv[2]);
        goto failure;
    }
    if ((profile = psp_readfile(argv[3], parent)) == NULL) {
        fprintf(stderr, "Unable to open profile: %s\n", argv[3]);
        goto failure;
    }

    /* Current directory. */
    // FIXME: #1656, C ABI, hardcoded cache dir
    const char *cache_dir = ".";
//    const char *cache_dir = mkdtemp("psp");

    psp_tunnel_start_args args = { 0 };
    args.bundle = bundle;
    args.constants = constants;
    args.preferences = NULL;
    args.cache_dir = cache_dir;
    args.profile = profile;
    args.is_interactive = true;
    args.is_daemon = true;
    args.jni_wrapper = NULL;

    /* Will block indefinitely. */
    psp_tunnel_start(&args, NULL, start_callback);

    free(bundle);
    free(constants);
    free(profile);
    return 0;
failure:
    if (bundle) free(bundle);
    if (constants) free(constants);
    if (profile) free(profile);
    return -1;
}
