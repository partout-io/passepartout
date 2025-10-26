// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

function getInfrastructure(module, headers) {
    const providerId = "ivpn";
    const openVPN = {
        moduleType: "OpenVPN",
        presetIds: {
            recommended: "default"
        }
    };

    const json = api.getJSON("https://api.ivpn.net/v5/servers.json", headers);
    if (!json.response) {
        return json;
    }

    const servers = [];
    json.response.openvpn.forEach(server => {
        const hostname = server.gateway;
        const hostnameComps = hostname.split(".");

        const id = hostnameComps[0];
        const country = server.country_code;
        const category = "";
        const area = server.city;
        const extraCountry = null;

        const resolved = server.hosts.map(h => h.host);
        const addresses = resolved.map(addr => api.ipV4ToBase64(addr));

        const serverObj = {
            serverId: id,
            hostname: hostname,
            ipAddresses: addresses,
            supportedModuleTypes: [openVPN.moduleType]
        };
        const metadata = {
            providerId: providerId
        };
        metadata.countryCode = country.toUpperCase();
        metadata.categoryName = category || "Default";
        if (extraCountry) metadata.extraCountryCodes = [extraCountry.toUpperCase()];
        if (area) metadata.area = area;
        if (!hostname) {
            serverObj.resolved = true;
        } else {
            serverObj.hostname = hostname;
        }
        serverObj.ipAddresses = addresses;
        serverObj.metadata = metadata;

        servers.push(serverObj);
    });

    const presets = getOpenVPNPresets(providerId, openVPN.moduleType, openVPN.presetIds, json.response.config.ports.openvpn);

    return {
        response: {
            presets: presets,
            servers: servers,
            cache: json.cache
        }
    };
}

// MARK: OpenVPN

function getOpenVPNPresets(providerId, moduleType, presetIds, ports) {
    const ca = `
-----BEGIN CERTIFICATE-----
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
sWGIGABGAHwXEAoDiZ/jjFrEZT0=
-----END CERTIFICATE-----
`;

    const tlsAuthKey = `
ac470c93ff9f5602a8aab37dee84a528
14d10f20490ad23c47d5d82120c1bf85
9e93d0696b455d4a1b8d55d40c2685c4
1ca1d0aef29a3efd27274c4ef09020a3
978fe45784b335da6df2d12db97bbb83
8416515f2a96f04715fd28949c6fe296
a925cfada3f8b8928ed7fc963c156327
2f5cf46e5e1d9c845d7703ca881497b7
e6564a9d1dea9358adffd435295479f4
7d5298fabf5359613ff5992cb57ff081
a04dfb81a26513a6b44a9b5490ad265f
8a02384832a59cc3e075ad545461060b
7bcab49bac815163cb80983dd51d5b1f
d76170ffd904d8291071e96efc3fb777
856c717b148d08a510f5687b8a8285dc
ffe737b98916dd15ef6235dee4266d3b
`;

    const tlsWrap = api.openVPNTLSWrap("auth", tlsAuthKey);

    const cfg = {
        ca: ca,
        cipher: "AES-256-CBC",
        digest: "SHA1",
        compressionFraming: 0,
        tlsWrap: tlsWrap
    };

    const recommended = {
        providerId: providerId,
        presetId: presetIds.recommended,
        description: "Default",
        moduleType: moduleType
    };

    const endpoints = [];
    ports.forEach(map => {
        const singlePort = map.port;
        if (!singlePort) return;
        const proto = map.type;
        endpoints.push(`${proto}:${singlePort}`);
    });
    recommended.templateData = api.jsonToBase64({
        configuration: cfg,
        endpoints: endpoints
    });

    return [recommended];
}
