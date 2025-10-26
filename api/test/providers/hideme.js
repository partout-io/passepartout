// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import { describe, it } from "mocha";
import { strict as assert } from "assert";
import * as setup from "../setup.js";

describe("hideme", () => {
    let infra;
    before(() => {
        const json = setup.fetchMockInfrastructure("hideme");
        infra = json.response;
    });
    it("should have 1 preset", () => {
        assert.strictEqual(infra.presets.length, 1);
    });
    it("should have 7 servers", () => {
        assert.strictEqual(infra.servers.length, 7);
    });
    it("preset 0 should use CBC and 22 endpoints", () => {
        const preset = infra.presets[0];
        assert.strictEqual(preset.moduleType, "OpenVPN");
        const template = setup.templateFrom(preset);
        const cfg = template.configuration;
        assert.strictEqual(cfg.cipher, "AES-256-CBC");
        assert.strictEqual(cfg.digest, "SHA256");
        assert.deepStrictEqual(template.endpoints, [
            "UDP:3000", "UDP:3010", "UDP:3020", "UDP:3030", "UDP:3040", "UDP:3050",
            "UDP:3060", "UDP:3070", "UDP:3080", "UDP:3090", "UDP:3100",
            "TCP:3000", "TCP:3010", "TCP:3020", "TCP:3030", "TCP:3040", "TCP:3050",
            "TCP:3060", "TCP:3070", "TCP:3080", "TCP:3090", "TCP:3100"
        ]);
    });
});
