// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import { describe, it } from "mocha";
import { strict as assert } from "assert";
import * as setup from "../setup.js";

describe("mullvad", () => {
    let infra;
    before(() => {
        const json = setup.fetchMockInfrastructure("mullvad");
        infra = json.response;
    });
    it("should have 3 presets", () => {
        assert.strictEqual(infra.presets.length, 3);
    });
    it("should have 6 servers", () => {
        assert.strictEqual(infra.servers.length, 6);
    });
    it("preset 0 should use CBC and 9 endpoints", () => {
        const preset = infra.presets[0];
        assert.strictEqual(preset.moduleType, "OpenVPN");
        const template = setup.templateFrom(preset);
        const cfg = template.configuration;
        assert.strictEqual(cfg.cipher, "AES-256-CBC");
        assert.deepStrictEqual(template.endpoints, [
            "UDP:1194", "UDP:1195", "UDP:1196", "UDP:1197",
            "UDP:1300", "UDP:1301", "UDP:1302", "TCP:443", "TCP:80"
        ]);
    });
    it("preset 1 should use CBC and 2 endpoints", () => {
        const preset = infra.presets[1];
        assert.strictEqual(preset.moduleType, "OpenVPN");
        const template = setup.templateFrom(preset);
        const cfg = template.configuration;
        assert.strictEqual(cfg.cipher, "AES-256-CBC");
        assert.deepStrictEqual(template.endpoints, [
            "UDP:1400", "TCP:1401"
        ]);
    });
});
