// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import { describe, it } from "mocha";
import { strict as assert } from "assert";
import * as setup from "../setup.js";

describe("surfshark", () => {
    let infra;
    before(() => {
        const json = setup.fetchMockInfrastructure("surfshark");
        infra = json.response;
    });
    it("should have 1 preset", () => {
        assert.strictEqual(infra.presets.length, 1);
    });
    it("should have 3 servers", () => {
        assert.strictEqual(infra.servers.length, 3);
    });
    it("preset 0 should use CBC and 2 endpoints", () => {
        const preset = infra.presets[0];
        assert.strictEqual(preset.moduleType, "OpenVPN");
        const template = setup.templateFrom(preset);
        const cfg = template.configuration;
        assert.strictEqual(cfg.cipher, "AES-256-CBC");
        assert.strictEqual(cfg.digest, "SHA512");
        assert.deepStrictEqual(template.endpoints, [
            "UDP:1194", "TCP:1443"
        ]);
    });
});
