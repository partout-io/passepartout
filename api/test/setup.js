// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import { api } from "../lib/api.js";
import { fetchInfrastructure } from "../lib/context.js";

export function fetchMockInfrastructure(providerId) {
    return fetchInfrastructure(api, providerId, {
        responsePath: `test/mock/providers/${providerId}/fetch.json`,
        preferCache: false, // run real-world script
    });
}

export function templateFrom(preset) {
    try {
        const jsonString = Buffer.from(preset.templateData, "base64").toString("utf8");
        return JSON.parse(jsonString);
    } catch (error) {
        console.error(`Unable to parse template: ${error}`);
        throw error;
    }
}
