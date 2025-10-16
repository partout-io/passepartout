// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import { describe, it } from "mocha";
import { strict as assert } from "assert";
import * as setup from "../setup.js";

describe("ivpn", () => {
    let infra;
    before(() => {
        const json = setup.fetchMockInfrastructure("ivpn");
        infra = json.response;
    });
    it("should have 1 preset", () => {
        assert.strictEqual(infra.presets.length, 1);
    });
    it("should have 2 servers", () => {
        assert.strictEqual(infra.servers.length, 2);
    });
    it("preset 0 should use CBC and 16 endpoints", () => {
        const preset = infra.presets[0];
        assert.strictEqual(preset.moduleType, "OpenVPN");
        const template = setup.templateFrom(preset);
        const cfg = template.configuration;
        assert.strictEqual(cfg.cipher, "AES-256-CBC");
        assert.strictEqual(cfg.digest, "SHA1");
        assert.deepStrictEqual(template.endpoints, [
            "UDP:53", "UDP:80", "UDP:123", "UDP:2049",
            "UDP:2050", "UDP:443", "UDP:1194", "TCP:80",
            "TCP:443", "TCP:1194", "TCP:2049", "TCP:2050",
            "TCP:30587", "TCP:41893", "TCP:48574", "TCP:58237"
        ]);
    });
});
