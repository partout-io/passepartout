// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

function getInfrastructure(module, headers) {
    const providerId = "oeck";
    const openVPN = {
        moduleType: "OpenVPN",
        presetIds: {
            cfg128: "cfg128",
            cfg256: "cfg256"
        }
    };

    const json = api.getJSON("https://www.oeck.com/oeck-servers.json", headers);
    if (!json.response) {
        return json;
    }

    const servers = [];
    json.response["countries"].forEach(country => {
        country["cities"].forEach(city => {
            const code = country["code"].toUpperCase();
            const area = city["name"];

            city["relays"].forEach(relay => {
                const id = relay["hostname"];
                const hostname = `${id}.oeck.com`;
                const num = parseInt(id.split("-").pop(), 10);

                const addresses = [relay["ipv4_addr_in"]].map(a => {
                    return api.ipV4ToBase64(a);
                });

                const server = {
                    serverId: id,
                    hostname: hostname,
                    ipAddresses: addresses,
                    supportedModuleTypes: [openVPN.moduleType]
                };
                const metadata = {
                    providerId: providerId,
                    categoryName: "Default",
                    countryCode: code
                }
                if (area.trim() !== "") {
                    metadata.area = area;
                    metadata.num = num;
                }
                server.metadata = metadata;

                servers.push(server);
            });
        });
    });

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
MIIFKDCCAxCgAwIBAgIJAP8Xr7kyElHFMA0GCSqGSIb3DQEBCwUAMBIxEDAOBgNV
BAMMB09lY2stQ0EwHhcNMTkwNzIwMDExMzQxWhcNMjkwNzE3MDExMzQxWjASMRAw
DgYDVQQDDAdPZWNrLUNBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
nwwLAP1y7KPMrj6LeJ8jSAx+WhN002CNX4TikHrbXXG3h0Z2DefuKHaF0qFN2uFz
0cwzWj8DUMBeXIalwCO/EaY2CjbGYKNzxCxNq65r1qyfiprqq4RfEaAXOJibO2HW
IQyKCzycEuys2RJz9V8DZoMcIB1ptcZKspeA9xe7/vTG68PR9lsBRDoORZ3nte9a
fiRdiqqc9w3SZttPOdM9Qd0cQLAZQ6QgTiwCAzjamVA1au+ifN3WGRPZr0ETrzZ2
7YRX0uHevUtRrilhXyndbOHoLLv5v4EoFqyTq1nbhFv1CwBfGa9vMfH7oAnuqK7w
B6JeKXELlINbcWy7i2G1/VBl483n6NMwxP0XeQdel2rqNKZYi9aqqXE1sSdg6TW9
VZT+KbiLRhcHFNUliia43O36o+OmyuhVOSJe/YhotQqHVt6+xEQyfq7FBOvzW0ZC
dFUoIPSECoLUujKBu9aHco/PkoMhtGANYstbLkOlSX/+QT7yUsH9GDpr1681IK7u
J8xg3gtt9uMVhNoBRgIFRyGHGp2aOAo3BW7QUvMP9IQdzHFRIqku/sjL2+W678ve
yuTe8h1vW/LsYFVciE9jd1EnRJ7VI/ZMIS7QJhXBz8ThKMOXvpMYBoiBu2KbG31d
OdjZxid22JXgITeEGg+rEDTdTlnoecYooZFPKfq3XWkCAwEAAaOBgDB+MB0GA1Ud
DgQWBBQ03329sopZ0n6imn6jnJYKgEYudTBCBgNVHSMEOzA5gBQ03329sopZ0n6i
mn6jnJYKgEYudaEWpBQwEjEQMA4GA1UEAwwHT2Vjay1DQYIJAP8Xr7kyElHFMAwG
A1UdEwQFMAMBAf8wCwYDVR0PBAQDAgEGMA0GCSqGSIb3DQEBCwUAA4ICAQCTa0cM
9ci03iYS+rMBpFvageMBufgJNrBhFXW9kFI9ObmL9mLroOaedCIlGeLTX8nV5WXr
iSfGaq4b/fE43DbknUX21MUm8Y+LZI/IMj2x8kDgmzfsW2bve970zDhaUGyu7pqt
ZiNtoBE6IPZdVSNlRIKIHEYiDVZAlv7rDyFm0mRaBTkjIcDmXSWsXmlDoXtzqNat
rvgAsyJSBILl1r02ol7cWDZiZppbOyvzYK7hQ4SxIdXt486OnNCi+Qj1xnkCPofb
Z4U0F90+h1kxyRd/xveTjwrLSQ1gikati7MpI1ihCun0oYSDZ7X6hlsrsk8o1/rx
tVoLiBIEr15wsWKSjAY6n3Vt1oUw0mhOhGHR0DiBVCBkBwKfrL1hACFrYo2819lo
ZEYLFbQfeo7jR61X+9Ee9Cxt325knrn9uoEqzVXEHv9DBD248eO6aSoLxQ1+d15o
zIBSaS/7qs0LUB8Dc68XTupmkWHt+9aFkAQ6v+OUs+uUr7sFbGTk5TtJsv6mJLs0
4aTDGTS8hLObAAOoXNtdq4Z9u02xpPn0ZaPVOabr2nec/37O7mFDw238DtgR627K
6PrOkTanIVsUl/lU4a6ZmQgNXUC8NCHU3kb/bRyJjaW1erkNUj9DWEBjXNHL9Q/7
Z+180e2WQvsBhRuICzDjiLGkL1sQxy1OhHQMEQ==
-----END CERTIFICATE-----
`;

    const clientCertificate = `
-----BEGIN CERTIFICATE-----
MIIFSzCCAzOgAwIBAgIRAKNHjxCfvQGDLUMmgGjdl9IwDQYJKoZIhvcNAQELBQAw
EjEQMA4GA1UEAwwHT2Vjay1DQTAeFw0yMzA1MjIyMzQzMDJaFw0yNjA1MDYyMzQz
MDJaMBoxGDAWBgNVBAMMD29lY2stcmxlV2ZyQ3BWdzCCAiIwDQYJKoZIhvcNAQEB
BQADggIPADCCAgoCggIBAL6+OlVn8+P4n7xAVE26x7aKEh2zpfNJj5LGcDj6+22D
lIh1T2TSEY6n6EAcIZJngfVkZ8lS3bYRe3aIYT1MBeqr6d1TjiGpZ6bDylTQdnOS
GfknFJCZVv3qNx5en1k+0X5iue4V4JF+i/tBy0opIVuxCCBZoJarSbn290QS3+2Z
jxjapAk7R02DUfxHlCFjH9UwGOwUBTSwHQIc8fbo6wHR5y1gYxisvuuSap164PRV
AZfXEK+cSLuyrKlnftY0ZLB4Nc/Ek1gWuCej1a6e6FBxgxxzM44Nu5k556tQe7Li
/EWjhvxw5WefM5WJEdOqqunnp9X4ZEFNxmN1xhqGHwGC/alHrQdVO27dmM/i/wnW
s7UZ/T9+tCRH0D+mz55DCAh5snycTQNknDoNGSiiRHcaXHKuYEUUPivbi7U9hxK3
6/27Lqsv8hcEkbEUOCkjtRgebeDnnSkLmTqhJPvkUSoAz4K9CbnKrvqn0gmTGwsy
ECumvAU3M3RjC7OWqeLKpDX7qtb1xxEVF/3m5BXsh7Ro7FCft5KoA+siGcUUBZSD
FZVy2exYxqfCtEbK1gSm+nd3yamlaGvBh/49U4MNLd3NHXx+0ARSOtt2pQcbHUcI
8TAQWRpp6U6isxQCGMKGq3CvgKEDMzahy72h7z+m/ix0ntXtBr9h1VWWpIQGuDO7
AgMBAAGjgZMwgZAwCQYDVR0TBAIwADAdBgNVHQ4EFgQU7JqDsw4x3+HoDDmCPQez
8ENtl/4wQgYDVR0jBDswOYAUNN99vbKKWdJ+opp+o5yWCoBGLnWhFqQUMBIxEDAO
BgNVBAMMB09lY2stQ0GCCQD/F6+5MhJRxTATBgNVHSUEDDAKBggrBgEFBQcDAjAL
BgNVHQ8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBACkHKWWqcb20CGA5Kpdz4Rgs
rNtMe0ThWNS+4sXYvhv/C82ZHLjmCltYcUT/H1A45CSnyL7u+xNAzPrm9ALczPov
yoDelDPtdlKLmmmKEOVNA6UyqRnd6CVGi+rCIz2fOj0e70exgcDQz2v2SAkNFI24
f428KXEm/8t9JSAeCP+RWdan7xLrjOCH4dT28NII0BLYI/JV/T0h6S5OGF1RCv3j
iJvI+C6//pshSp0wBHOX1zibXZul96agEnp70/LdBbegD9HzPP+FZ6pO8fe2xcVp
g2Trlbdxxd559no9+ZM2H1RhFsjGX6cUca5NwZf4Nh3VYL70rMvr2rAo06J37TX8
TBgWPUhV9yi0IL/kDQkTFrAQuy8XdR1FlFnmPQfA39n1kgTGUyE9S6DGPzPU4H7v
AOX6pxeM05dJjDhnTzSAUOPKvnTzzZy1EAyrXhXayBd9NcCjr+h7+xWTPsi6aOpp
fWOayCZ+Xmae6GDjnWmDW4+IKT1nG8ecHeVRzHm4j7RWoC/KOYYdz+ZkSuGZPEma
fr0BpfX16t0WWa84lgFXKP/3CY2qkQn20JIuymm0Wihg6OrMZ+APSjAmzdvv20Wr
uxLlorEJ3E+wlNCEOsLefXQ70Qfe6fkDXX7PNTo48a4gNghbldT8P2va2HPYYVMQ
dARcK+6g4U/cQov77W60
-----END CERTIFICATE-----
`;

    const clientKey = `
-----BEGIN PRIVATE KEY-----
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
urmxakp+jUtxNFnl+7Tt6gv0SghtLZY=
-----END PRIVATE KEY-----
`;

    const tlsAuthKey = `
13ecdb76b85a314995dddfae52bb6cee
54c0a20879850363a59f4229b80f3a37
b97dc212cdf4dcb946cc3946404209ee
979c2634e865fe9d761a870fb5cb60d1
0ee8e3b67e2c0b80efdad8343fdceb0a
0c85e677ff6d9332e10cb9b387c9c107
2ba0cedbba157311a9d0d426cef7ff35
6a034430ff98337567334e438e731560
01648d347cb548d721d3ef84df32782e
1a01ef14a4f93d874ecda2597b3d5393
dcb56452b7d5db5874e90627f84a34ed
8ae2cb48803cccb615dea17b77be5725
c901d03caa7d5eab10f957ff8b512c0a
a1013ba5842c5ae5b923a76f94d21d8e
b46d25416d608cc549e571dfffe64532
7f5dd208a85a1af6a25dede651b809fe
`;

    const tlsWrap = api.openVPNTLSWrap("auth", tlsAuthKey);

    const cfg = {
        ca: ca,
        clientCertificate: clientCertificate,
        clientKey: clientKey,
        compressionFraming: 0,
        tlsWrap: tlsWrap,
        checksEKU: true,
        authUserPass: true
    };

    const cfg128 = { ...cfg };
    cfg128.cipher = "AES-128-CBC";
    cfg128.digest = "SHA256";

    const cfg256 = { ...cfg };
    cfg256.cipher = "AES-256-GCM";
    cfg256.digest = "SHA256";

    const preset128 = {
        providerId: providerId,
        presetId: presetIds.cfg128,
        description: "128-bit",
        moduleType: moduleType,
        templateData: api.jsonToBase64({
            configuration: cfg128,
            endpoints: [
                "UDP:1196",
                "TCP:445"
            ]
        })
    };

    const preset256 = {
        providerId: providerId,
        presetId: presetIds.cfg256,
        description: "256-bit",
        moduleType: moduleType,
        templateData: api.jsonToBase64({
            configuration: cfg256,
            endpoints: [
                "UDP:1194",
                "TCP:443"
            ]
        })
    };

    return [preset128, preset256];
}
