// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import { describe, it } from "mocha";
import { strict as assert } from "assert";
import * as setup from "../setup.js";

describe("torguard", () => {
    let infra;
    before(() => {
        const json = setup.fetchMockInfrastructure("torguard");
        infra = json.response;
    });
    it("should have 2 presets", () => {
        assert.strictEqual(infra.presets.length, 2);
    });
    it("should have 68 servers", () => {
        assert.strictEqual(infra.servers.length, 68);
    });
    it("preset 0 should use CBC and 6 endpoints", () => {
        const preset = infra.presets[0];
        assert.strictEqual(preset.moduleType, "OpenVPN");
        const template = setup.templateFrom(preset);
        const cfg = template.configuration;
        assert.strictEqual(cfg.cipher, "AES-128-GCM");
        assert.strictEqual(cfg.digest, "SHA1");
        assert.deepStrictEqual(template.endpoints, [
            "UDP:80",
            "UDP:443",
            "UDP:995",
            "TCP:80",
            "TCP:443",
            "TCP:995"
        ]);
    });
    it("preset 1 should use GCM and 8 endpoints", () => {
        const preset = infra.presets[1];
        assert.strictEqual(preset.moduleType, "OpenVPN");
        const template = setup.templateFrom(preset);
        const cfg = template.configuration;
        assert.strictEqual(cfg.cipher, "AES-256-GCM");
        assert.strictEqual(cfg.digest, "SHA256");
        assert.deepStrictEqual(template.endpoints, [
            "UDP:53",
            "UDP:501",
            "UDP:1198",
            "UDP:9201",
            "TCP:53",
            "TCP:501",
            "TCP:1198",
            "TCP:9201"
    ]);
    });
});
