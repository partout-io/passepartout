// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import { api, modes, allProviders } from "./lib/api.js";
import { fetchInfrastructure } from "./lib/context.js";
import { mkdir, writeFile } from "fs/promises";

async function cacheProvidersInParallel(ids, mode) {
    try {
        const writePromises = ids
            .map(async providerId => {
                const providerPath = `cache/${api.root}/${api.version}/providers/${providerId}`;
                await mkdir(providerPath, { recursive: true });
                const dest = `${providerPath}/fetch.json`;
                const options = {
                    preferCache: mode == modes.PRODUCTION,
                    responseOnly: true
                };
                if (mode == modes.LOCAL_UNCACHED) {
                    options.responsePath = `test/mock/providers/${providerId}/fetch.json`;
                }
                const json = fetchInfrastructure(api, providerId, options);
                const minJSON = JSON.stringify(json);
                return writeFile(dest, minJSON, "utf8");
            });

        await Promise.all(writePromises);

        console.log("All files written successfully");
    } catch (error) {
        console.error("Error writing files:", error);
        throw error;
    }
}

// opt in
const arg = process.argv[2];
const mode = process.argv[3];
if (!arg) {
    console.error("Please provide a comma-separated list of provider IDs");
    process.exit(1);
}
const targetIds = arg.split(",");
await cacheProvidersInParallel(targetIds, mode);
