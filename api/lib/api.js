// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import fs from "fs";

export const api = {
    version: "v7",
    root: "src",
    index: "index.json"
};

export const modes = {
    LOCAL_UNCACHED: null,   // process local mock with full script
    REMOTE_UNCACHED: 1,     // process remote with full script
    PRODUCTION: 2           // process remote with cache script if available
};

export function allProviders(root) {
    const excludedProviders = new Set([]);
    const apiIndex = `${root}/${api.root}/${api.version}/index.json`;
    const data = JSON.parse(fs.readFileSync(apiIndex, "utf8"));
    return data.providers
        .map(provider => provider.id)
        .filter(id => !excludedProviders.has(id));
}
