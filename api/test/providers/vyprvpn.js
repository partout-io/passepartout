// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import { describe, it } from "mocha";
import { strict as assert } from "assert";
import * as setup from "../setup.js";

describe("vyprvpn", () => {
    let infra;
    before(() => {
        const json = setup.fetchMockInfrastructure("vyprvpn");
        infra = json.response;
    });
    it("should have 1 preset", () => {
        assert.strictEqual(infra.presets.length, 1);
    });
    it("should have 73 servers", () => {
        assert.strictEqual(infra.servers.length, 73);
    });
    it("preset 0 should use CBC and 1 endpoint", () => {
        const preset = infra.presets[0];
        assert.strictEqual(preset.moduleType, "OpenVPN");
        const template = setup.templateFrom(preset);
        const cfg = template.configuration;
        assert.strictEqual(cfg.cipher, "AES-256-GCM");
        assert.strictEqual(cfg.digest, "SHA1");
        assert.deepStrictEqual(template.endpoints, [
            "UDP:443"
        ]);
    });
});
