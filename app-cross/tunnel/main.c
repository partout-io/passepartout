/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <stdio.h>
#include <stdlib.h>
#include "partout.h"

int main(int argc, char *argv[]) {
    char *bundle = NULL;
    char *constants = NULL;
    char *profile = NULL;

    printf("Passepartout Tunnel (%s)\n", partout_version());
//    if (argc <= 3) {
//        fprintf(stderr, "Missing path to bundle, constants, profile\n");
//        return -1;
//    }
    if (argc <= 1) {
        fprintf(stderr, "Missing path to profile\n");
        return -1;
    }

#ifdef USE_SWIFTPM
    const char *parent = "app-cross_passepartout-shared.bundle/Contents/Resources/assets";
#else
    const char *parent = NULL;
#endif

    /* Paths to JSON input. */
//    if ((bundle = partout_readfile(argv[1], parent)) == NULL) {
//        fprintf(stderr, "Unable to open bundle: %s\n", argv[1]);
//        goto failure;
//    }
//    if ((constants = partout_readfile(argv[2], parent)) == NULL) {
//        fprintf(stderr, "Unable to open constants: %s\n", argv[2]);
//        goto failure;
//    }
    if ((profile = partout_readfile(argv[1], parent)) == NULL) {
        fprintf(stderr, "Unable to open profile: %s\n", argv[1]);
        goto failure;
    }

    /* Initialize library (for logging). */
    const partout_init_args init_args = {
        .log_tag = NULL,
        .logs_private_data = false
    };
    partout_init(&init_args);

    /* Current directory. */
    // FIXME: #209/notes, Cross UI, hardcoded values
    const char *cache_dir = ".";
//    const char *cache_dir = mkdtemp("psp");
    const char *preferences = "{\"deviceId\":\"abcdef\"}";

    const partout_daemon_start_args start_args = {
        .cache_dir = cache_dir,
        .profile = profile,
        .is_daemon = true,
        .bindings = NULL
    };

    /* Will block indefinitely. */
    const int result = partout_daemon_start(&start_args);

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
