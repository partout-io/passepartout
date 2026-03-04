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
    if (parent) {
        size_t path_len = snprintf(NULL, 0, "%s/%s", parent, rel_path);
        abs_path = calloc(1, path_len + 1);
        snprintf(abs_path, path_len + 1, "%s/%s", parent, rel_path);
    } else {
        abs_path = strdup(rel_path);
    }
    FILE *file = fopen(abs_path, "rb");
    free(abs_path);

    if (!file) return NULL;
    if (fseek(file, 0, SEEK_END) != 0) {
        fclose(file);
        return NULL;
    }
    long size = ftell(file);
    if (size < 0) {
        fclose(file);
        return NULL;
    }
    rewind(file);
    // Allocate buffer (+1 for null terminator)
    char *buffer = malloc(size + 1);
    if (!buffer) {
        fclose(file);
        return NULL;
    }
    size_t read_size = fread(buffer, 1, size, file);
    fclose(file);
    if (read_size != (size_t)size) {
        free(buffer);
        return NULL;
    }
    buffer[size] = '\0';  // Null-terminate
    return buffer;
}
