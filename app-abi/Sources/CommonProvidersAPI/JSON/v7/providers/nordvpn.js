// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

function getInfrastructure(module, headers, preferCache) {
    const providerId = "nordvpn";
    if (preferCache) {
        const json = api.getJSON("https://passepartoutvpn.app/api-cache/v7/providers/nordvpn/fetch.json", headers);
        if (json && json.response) {
            json.response.cache = json.cache;
        }
        return json;
    }

    const openVPN = {
        moduleType: "OpenVPN",
        presetIds: {
            basic: "default",
            double: "double"
        }
    };
    const json = api.getJSON("https://api.nordvpn.com/v2/servers?limit=0", headers);
    if (!json.response) {
        return json;
    }

    const regions = {};
    for (const entry of json.response.locations) {
        regions[entry.id] = entry;
    }

    const groups = {};
    for (const entry of json.response.groups) {
        groups[entry.id] = entry;
    }

    const servers = [];
    for (const entry of json.response.servers) {
        const hostname = entry.hostname;
        const id = hostname.split(".")[0];
        const locations = entry.location_ids.map(li => regions[li]);
        if (locations.length == 0) {
            continue;
        }
        const [location, ...otherLocations] = locations;
        if (!location.country) {
            continue;
        }
        const code = location.country.code;
        const extraCodes = otherLocations.map(loc => loc.country.code);
        const area = location.country.city ? location.country.city.name : null;

        const isDoubleVPN = entry.group_ids.includes(g => g.id == 1);

        const server = {
            serverId: id,
            hostname: hostname,
            supportedModuleTypes: [openVPN.moduleType],
            supportedPresetIds: [isDoubleVPN ? openVPN.presetIds.double : openVPN.presetIds.basic]
        };

        if (entry.ips) {
            let addrs = [];
            entry.ips.forEach(obj => {
                if (obj.ip && obj.ip.version == 4) {
                    addrs.push(api.ipV4ToBase64(obj.ip.ip));
                }
            });
            server.ipAddresses = addrs;
        }

        const metadata = {
            providerId: providerId,
            countryCode: code,
            categoryName: isDoubleVPN ? "Double VPN" : "Default"
        };
        if (area) {
            metadata.area = area;
        }
        server.metadata = metadata;

        servers.push(server);
    }

    const presets = getOpenVPNPresets(providerId, openVPN.moduleType, openVPN.presetIds);

    return {
        response: {
            presets: presets,
            servers: servers,
            cache: json.cache
        }
    };
}

// MARK: OpenVPN

function getOpenVPNPresets(providerId, moduleType, presetIds) {
    const ca = `
-----BEGIN CERTIFICATE-----
MIIFCjCCAvKgAwIBAgIBATANBgkqhkiG9w0BAQ0FADA5MQswCQYDVQQGEwJQQTEQ
MA4GA1UEChMHTm9yZFZQTjEYMBYGA1UEAxMPTm9yZFZQTiBSb290IENBMB4XDTE2
MDEwMTAwMDAwMFoXDTM1MTIzMTIzNTk1OVowOTELMAkGA1UEBhMCUEExEDAOBgNV
BAoTB05vcmRWUE4xGDAWBgNVBAMTD05vcmRWUE4gUm9vdCBDQTCCAiIwDQYJKoZI
hvcNAQEBBQADggIPADCCAgoCggIBAMkr/BYhyo0F2upsIMXwC6QvkZps3NN2/eQF
kfQIS1gql0aejsKsEnmY0Kaon8uZCTXPsRH1gQNgg5D2gixdd1mJUvV3dE3y9FJr
XMoDkXdCGBodvKJyU6lcfEVF6/UxHcbBguZK9UtRHS9eJYm3rpL/5huQMCppX7kU
eQ8dpCwd3iKITqwd1ZudDqsWaU0vqzC2H55IyaZ/5/TnCk31Q1UP6BksbbuRcwOV
skEDsm6YoWDnn/IIzGOYnFJRzQH5jTz3j1QBvRIuQuBuvUkfhx1FEwhwZigrcxXu
MP+QgM54kezgziJUaZcOM2zF3lvrwMvXDMfNeIoJABv9ljw969xQ8czQCU5lMVmA
37ltv5Ec9U5hZuwk/9QO1Z+d/r6Jx0mlurS8gnCAKJgwa3kyZw6e4FZ8mYL4vpRR
hPdvRTWCMJkeB4yBHyhxUmTRgJHm6YR3D6hcFAc9cQcTEl/I60tMdz33G6m0O42s
Qt/+AR3YCY/RusWVBJB/qNS94EtNtj8iaebCQW1jHAhvGmFILVR9lzD0EzWKHkvy
WEjmUVRgCDd6Ne3eFRNS73gdv/C3l5boYySeu4exkEYVxVRn8DhCxs0MnkMHWFK6
MyzXCCn+JnWFDYPfDKHvpff/kLDobtPBf+Lbch5wQy9quY27xaj0XwLyjOltpiST
LWae/Q4vAgMBAAGjHTAbMAwGA1UdEwQFMAMBAf8wCwYDVR0PBAQDAgEGMA0GCSqG
SIb3DQEBDQUAA4ICAQC9fUL2sZPxIN2mD32VeNySTgZlCEdVmlq471o/bDMP4B8g
nQesFRtXY2ZCjs50Jm73B2LViL9qlREmI6vE5IC8IsRBJSV4ce1WYxyXro5rmVg/
k6a10rlsbK/eg//GHoJxDdXDOokLUSnxt7gk3QKpX6eCdh67p0PuWm/7WUJQxH2S
DxsT9vB/iZriTIEe/ILoOQF0Aqp7AgNCcLcLAmbxXQkXYCCSB35Vp06u+eTWjG0/
pyS5V14stGtw+fA0DJp5ZJV4eqJ5LqxMlYvEZ/qKTEdoCeaXv2QEmN6dVqjDoTAo
k0t5u4YRXzEVCfXAC3ocplNdtCA72wjFJcSbfif4BSC8bDACTXtnPC7nD0VndZLp
+RiNLeiENhk0oTC+UVdSc+n2nJOzkCK0vYu0Ads4JGIB7g8IB3z2t9ICmsWrgnhd
NdcOe15BincrGA8avQ1cWXsfIKEjbrnEuEk9b5jel6NfHtPKoHc9mDpRdNPISeVa
wDBM1mJChneHt59Nh8Gah74+TM1jBsw4fhJPvoc7Atcg740JErb904mZfkIEmojC
VPhBHVQ9LHBAdM8qFI2kRK0IynOmAZhexlP/aT/kpEsEPyaZQlnBn3An1CRz8h0S
PApL8PytggYKeQmRhl499+6jLxcZ2IegLfqq41dzIjwHwTMplg+1pKIOVojpWA==
-----END CERTIFICATE-----
`;

    const tlsAuthKey = `
e685bdaf659a25a200e2b9e39e51ff03
0fc72cf1ce07232bd8b2be5e6c670143
f51e937e670eee09d4f2ea5a6e4e6996
5db852c275351b86fc4ca892d78ae002
d6f70d029bd79c4d1c26cf14e9588033
cf639f8a74809f29f72b9d58f9b8f5fe
fc7938eade40e9fed6cb92184abb2cc1
0eb1a296df243b251df0643d53724cdb
5a92a1d6cb817804c4a9319b57d53be5
80815bcfcb2df55018cc83fc43bc7ff8
2d51f9b88364776ee9d12fc85cc7ea5b
9741c4f598c485316db066d52db4540e
212e1518a9bd4828219e24b20d88f598
a196c9de96012090e333519ae18d3509
9427e7b372d348d352dc4c85e18cd4b9
3f8a56ddb2e64eb67adfc9b337157ff4
`;

    const tlsWrap = api.openVPNTLSWrap("auth", tlsAuthKey);

    const cfg = {
        ca: ca,
        cipher: "AES-256-CBC",
        digest: "SHA512",
        compressionFraming: 1,
        tlsWrap: tlsWrap,
        keepAliveInterval: 15,
        renegotiatesAfter: 0,
        checksEKU: true,
        randomizeEndpoint: true
    };

    const basic = {
        providerId: providerId,
        presetId: presetIds.basic,
        description: "Default",
        moduleType: moduleType,
        templateData: api.jsonToBase64({
            configuration: cfg,
            endpoints: [
                "UDP:1194"
            ]
        })
    };
    const double = {
        providerId: providerId,
        presetId: presetIds.double,
        description: "Double VPN",
        moduleType: moduleType,
        templateData: api.jsonToBase64({
            configuration: cfg,
            endpoints: [
                "TCP:443"
            ]
        })
    };

    return [basic, double];
}
