// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

function getInfrastructure(module, headers) {
    const providerId = "tunnelbear";
    const openVPN = {
        moduleType: "OpenVPN",
        presetIds: {
            recommended: "default"
        }
    };

    // XXX: hardcoded country names
    const mergedCountries = "AR AU AT BE BR BG CA CL CO CY CZ DK FI FR DE GR HU ID IE IT JP KE LV LT MY MX MD NL NZ NG NO PE PH PL PT RO RS SG SI ZA KR ES SE CH TW GB US";
    const countries = mergedCountries.split(" ");

    const servers = [];
    for (const country of countries) {
        const id = country.toLowerCase();
        const hostname = `${id}.lazerpenguin.com`;
        const server = {
            serverId: id,
            hostname: hostname,
            supportedModuleTypes: [openVPN.moduleType]
        };
        const metadata = {
            providerId: providerId,
            countryCode: country,
            categoryName: "Default"
        };
        server.metadata = metadata;

        servers.push(server);
    }

    const presets = getOpenVPNPresets(providerId, openVPN.moduleType, openVPN.presetIds);

    return {
        response: {
            presets: presets,
            servers: servers
        }
    };
}

// MARK: OpenVPN

function getOpenVPNPresets(providerId, moduleType, presetIds) {
    const ca = `
-----BEGIN CERTIFICATE-----
MIICPTCCAcOgAwIBAgIQfs/kxYEHK0ojKgXA1FrgFjAKBggqhkjOPQQDAjBgMQsw
CQYDVQQGEwJDQTEUMBIGA1UECgwLTWNBZmVlLCBMTEMxDDAKBgNVBAsMA1ZQTjEt
MCsGA1UEAwwkTWNBZmVlIE9wZW5WUE4gQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4X
DTI0MDgwNjIwMzM0N1oXDTM0MDgwNjIxMzI0N1owYDELMAkGA1UEBhMCQ0ExFDAS
BgNVBAoMC01jQWZlZSwgTExDMQwwCgYDVQQLDANWUE4xLTArBgNVBAMMJE1jQWZl
ZSBPcGVuVlBOIENlcnRpZmljYXRlIEF1dGhvcml0eTB2MBAGByqGSM49AgEGBSuB
BAAiA2IABNJps+fTiqQfpGzgpq9yAPM0rLzVZ1qscVxqag3ESsclEp/uk+HCAwK1
EiLER8xXXweW9jVcYEHLuUkmBL+0FjocD5lI6zbrwaY8gWOz8vAP0fjolhXQgHfH
TqrYC9unIqNCMEAwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUwa+4wbD5vocC
xKeVNouzvsSPLekwDgYDVR0PAQH/BAQDAgGGMAoGCCqGSM49BAMCA2gAMGUCMGIM
dRbutNNzP8GIyGHKtPd+7CSOlpqeBOUBsGLkj4F1y7/yqv7hIchtTIZQymmthAIx
APY7ZiCKYW7L0mLVgowDRSY95Qxrs9NjsyQxlqRdMKcQfrojIH8Dh931M5Sj7EqR
eg==
-----END CERTIFICATE-----
`;

    const cfg = {
        ca: ca,
        cipher: "AES-256-CBC",
        digest: "SHA256",
        compressionFraming: 1,
        keepAliveInterval: 10,
        checksEKU: true
    };

    const recommended = {
        providerId: providerId,
        presetId: presetIds.recommended,
        description: "Default",
        moduleType: moduleType,
        templateData: api.jsonToBase64({
            configuration: cfg,
            endpoints: [
                "UDP:443",
                "UDP:7011",
                "TCP:443"
            ]
        })
    };

    return [recommended]
}
