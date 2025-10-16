// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import { describe, it } from "mocha";
import { strict as assert } from "assert";
import * as setup from "../setup.js";

describe("windscribe", () => {
    let infra;
    before(() => {
        const json = setup.fetchMockInfrastructure("windscribe");
        infra = json.response;
    });
    it("should have 1 preset", () => {
        assert.strictEqual(infra.presets.length, 1);
    });
    it("should have 72 servers", () => {
        assert.strictEqual(infra.servers.length, 72);
    });
    it("preset 0 should use GCM and 6 endpoints", () => {
        const preset = infra.presets[0];
        assert.strictEqual(preset.moduleType, "OpenVPN");
        const template = setup.templateFrom(preset);
        const cfg = template.configuration;
        assert.strictEqual(cfg.cipher, "AES-256-GCM");
        assert.strictEqual(cfg.digest, "SHA512");
        assert.deepStrictEqual(template.endpoints, [
            "UDP:443",
            "UDP:80",
            "UDP:53",
            "UDP:1194",
            "UDP:54783",
            "TCP:443",
            "TCP:587",
            "TCP:21",
            "TCP:22",
            "TCP:80",
            "TCP:143",
            "TCP:3306",
            "TCP:8080",
            "TCP:54783",
            "TCP:1194"
        ]);
    });
});
