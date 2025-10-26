// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

function getInfrastructure(module, headers) {
    const providerId = "windscribe";
    const openVPN = {
        moduleType: "OpenVPN",
        presetIds: {
            recommended: "default"
        }
    };

    // XXX: hardcoded servers
    // https://windscribe.com/features/large-network
    const countriesCSV = `
al|AL||
aq|AQ||
ar|AR||
at|AT||
au|AU||
az|AZ||
ba|BA||
be|BE||
bg|BG||
br|BR||
ca|CA||
ch|CH||
cl|CL||
co|CO||
cy|CY||
cz|CZ||
de|DE||
dk|DK||
ec|EC||
ee|EE||
es|ES||
fi|FI||
fr|FR||
gh|GH||
gr|GR||
hk|HK||
hr|HR||
hu|HU||
id|ID||
ie|IE||
il|IL||
in|IN||
is|IS||
it|IT||
jp|JP||
ke|KE||
kh|KH||
kr|KR||
lt|LT||
lv|LV||
md|MD||
mk|MK||
mx|MX||
my|MY||
nl|NL||
no|NO||
nz|NZ||
pa|PA||
pe|PE||
ph|PH||
pl|PL||
pt|PT||
ro|RO||
rs|RS||
ru|RU||
se|SE||
sg|SG||
sk|SK||
th|TH||
tr|TR||
tw|TW||
ua|UA||
uk|GB||
us-central|US|Central|
us-east|US|East|
us-west|US|West|
vn|VN||
za|ZA||
wf-ca|CA||Windflix
wf-jp|JP||Windflix
wf-uk|GB||Windflix
wf-us|US||Windflix
`
    const lines = countriesCSV.split("\n");

    const servers = [];
    for (const line of lines) {
        const comps = line.split("|");
        if (comps.length < 3) {
            continue;
        }
        const id = comps[0];
        const countryCode = comps[1];
        const hostname = `${id}.windscribe.com`;
        const server = {
            serverId: id,
            hostname: hostname,
            supportedModuleTypes: [openVPN.moduleType]
        };
        const metadata = {
            providerId: providerId,
            countryCode: countryCode
        };
        if (comps[2] != "") {
            metadata.area = comps[2];
        }
        if (comps[3] != "") {
            metadata.categoryName = comps[3];
        } else {
            metadata.categoryName = "Default";
        }
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
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
v7Dtup352gRS6qxW4w0jRN3NLfLyazK/JjTX
-----END CERTIFICATE-----
`;

    const tlsAuthKey = `
5801926a57ac2ce27e3dfd1dd6ef8204
2d82bd4f3f0021296f57734f6f1ea714
a6623845541c4b0c3dea0a050fe6746c
b66dfab14cda27e5ae09d7c155aa554f
399fa4a863f0e8c1af787e5c602a801d
3a2ec41e395a978d56729457fe6102d7
d9e9119aa83643210b33c678f9d4109e
3154ac9c759e490cb309b319cf708cae
83ddadc3060a7a26564d1a24411cd552
fe6620ea16b755697a4fc5e6e9d0cfc0
c5c4a1874685429046a424c026db672e
4c2c492898052ba59128d46200b40f88
0027a8b6610a4d559bdc9346d33a0a6b
08e75c7fd43192b162bfd0aef0c716b3
1584827693f676f9a5047123466f0654
eade34972586b31c6ce7e395f4b478cb
`;

    const tlsWrap = api.openVPNTLSWrap("auth", tlsAuthKey);

    const cfg = {
        ca: ca,
        cipher: "AES-256-GCM",
        digest: "SHA512",
        compressionFraming: 0,
        compressionAlgorithm: 0,
        tlsWrap: tlsWrap,
        checksEKU: false
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
            ]
        })
    };

    return [recommended]
}
