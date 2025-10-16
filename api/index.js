// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import { api, modes } from "./lib/api.js";
import { fetchInfrastructure, fetchRawInfrastructure } from "./lib/context.js";

const target = process.argv[2];
const mode = process.argv[3];
if (!target) {
    console.error("Please provide a provider ID or a file.js");
    process.exit(1);
}

let json;
const options = {
    preferCache: mode == modes.PRODUCTION
};
if (target.endsWith(".js")) {
    const filename = target;
    json = fetchRawInfrastructure(target, options);
} else {
    const providerId = target;
    if (mode == modes.LOCAL_UNCACHED) {
        options.responsePath = `test/mock/providers/${providerId}/fetch.json`;
    }
    json = fetchInfrastructure(api, providerId, options);
}
console.log(JSON.stringify(json, null, 2));
