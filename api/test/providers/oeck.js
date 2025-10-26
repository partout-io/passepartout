// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import { describe, it } from "mocha";
import { strict as assert } from "assert";
import * as setup from "../setup.js";

describe("oeck", () => {
    let infra;
    before(() => {
        const json = setup.fetchMockInfrastructure("oeck");
        infra = json.response;
    });
    it("should have 2 presets", () => {
        assert.strictEqual(infra.presets.length, 2);
    });
    it("should have 3 servers", () => {
        assert.strictEqual(infra.servers.length, 3);
    });
    it("preset 0 should use CBC and 2 endpoints", () => {
        const preset = infra.presets[0];
        assert.strictEqual(preset.moduleType, "OpenVPN");
        const template = setup.templateFrom(preset);
        const cfg = template.configuration;
        assert.strictEqual(cfg.cipher, "AES-128-CBC");
        assert.strictEqual(cfg.digest, "SHA256");
        assert.deepStrictEqual(template.endpoints, [
            "UDP:1196", "TCP:445"
        ]);
    });
    it("preset 1 should use GCM and 2 endpoints", () => {
        const preset = infra.presets[1];
        assert.strictEqual(preset.moduleType, "OpenVPN");
        const template = setup.templateFrom(preset);
        const cfg = template.configuration;
        assert.strictEqual(cfg.cipher, "AES-256-GCM");
        assert.strictEqual(cfg.digest, "SHA256");
        assert.deepStrictEqual(template.endpoints, [
            "UDP:1194", "TCP:443"
        ]);
    });
});
