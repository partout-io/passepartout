/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char *psp_strdup(const char *value) {
#ifdef _WIN32
    return _strdup(value);
#else
    return strdup(value);
#endif
}

static FILE *psp_fopen_read(const char *path) {
#ifdef _WIN32
    FILE *file = NULL;
    return (fopen_s(&file, path, "rb") == 0) ? file : NULL;
#else
    return fopen(path, "rb");
#endif
}

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
        abs_path = psp_strdup(rel_path);
        if (!abs_path) goto failure;
    }

    /* Open file at absolute path. */
    file = psp_fopen_read(abs_path);
    if (!file) goto failure;
    free(abs_path);
    abs_path = NULL;

    /* Compute file size. */
    if (fseek(file, 0, SEEK_END) != 0) goto failure;
    long size = ftell(file);
    if (size < 0) goto failure;
    rewind(file);

    /* Allocate buffer (+1 for '\0'). */
    size_t buffer_size = (size_t)size;
    if ((long)buffer_size != size) goto failure;
    if (buffer_size > SIZE_MAX - 1) goto failure;
    buffer = malloc(buffer_size + 1);
    if (!buffer) goto failure;
    size_t read_size = fread(buffer, 1, buffer_size, file);
    fclose(file);
    file = NULL;

    if (read_size != buffer_size) goto failure;
    buffer[buffer_size] = '\0';
    return buffer;
failure:
    if (buffer) free(buffer);
    if (file) fclose(file);
    if (abs_path) free(abs_path);
    return NULL;
}
