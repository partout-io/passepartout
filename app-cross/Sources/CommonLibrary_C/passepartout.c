/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *psp_readfile(const char *rel_path, const char *parent) {
    char *abs_path = NULL;
    FILE *file = NULL;
    char *buffer = NULL;

    /* Prepend parent if not NULL. */
    if (parent) {
        const int path_len = snprintf(NULL, 0, "%s/%s", parent, rel_path);
        if (path_len < 0) goto failure;
        abs_path = calloc(1, path_len + 1);
        if (!abs_path) goto failure;
        snprintf(abs_path, path_len + 1, "%s/%s", parent, rel_path);
    } else {
        abs_path = strdup(rel_path);
        if (!abs_path) goto failure;
    }

    /* Open file at absolute path. */
    file = fopen(abs_path, "rb");
    if (!file) goto failure;
    free(abs_path);
    abs_path = NULL;

    /* Compute file size. */
    if (fseek(file, 0, SEEK_END) != 0) goto failure;
    long size = ftell(file);
    if (size < 0 || (unsigned long)size > SIZE_MAX - 1) goto failure;
    rewind(file);

    /* Allocate buffer (+1 for '\0'). */
    buffer = malloc(size + 1);
    if (!buffer) goto failure;
    size_t read_size = fread(buffer, 1, size, file);
    fclose(file);
    file = NULL;

    if (read_size != (size_t)size) goto failure;
    buffer[size] = '\0';
    return buffer;
failure:
    if (buffer) free(buffer);
    if (file) fclose(file);
    if (abs_path) free(abs_path);
    return NULL;
}
