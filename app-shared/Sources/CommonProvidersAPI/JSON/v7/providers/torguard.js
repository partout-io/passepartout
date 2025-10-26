// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

function getInfrastructure(module, headers) {
    const providerId = "torguard";
    const openVPN = {
        moduleType: "OpenVPN",
        presetIds: {
            basic: "default",
            strong: "strong"
        }
    };

    // XXX: hardcoded servers
    // https://torguard.net/network/
    const countriesCSV = `
ar|AR|Buenos Aires
au|AU|Sydney
aus|AT|Vienna
bh|BH|Manama
bg|BE|Brussels
br|BR|Sau Paulo LOC1
br2|BR|Sau Paulo LOC2
bul|BG|Sofia
camtl|CA|Montréal
ca|CA|Toronto
cavan|CA|Vancouver
ch|CL|Vina del Mar
cz|CZ|Prague
dn|DK|Copenhagen
fn|FI|Helsinki
fr|FR|Paris
ger|DE|Frankfurt
gre|GR|Athens
hk|HK|Hong Kong
hg|HU|Budapest
ice|IS|Reykjavik
in|IN|Mumbai
id|ID|Jakarta
ire|IE|Dublin
isr-loc2|IL|Petah Tikva
isr-loc1|IL|Tel Aviv
it|IT|Milan
jp|JP|Tokyo
mx|MX|Mexico City
md|MD|Chisinau
nl|NL|Amsterdam
nz|NZ|Auckland
no|NO|Oslo
pl|PL|Warsaw
pg|PT|Lisbon
ro|RO|Bucharest
ru|RU|Moscow
serbia|RS|Belgrade
sg|SG|Singapore
slk|SK|Bratislava
sa|ZA|Johannesburg
sk|KR|Seoul
sp|ES|Madrid
swe|SE|Stockholm
swiss|CH|Zurich
tw|TW|Taipei
th|TH|Bangkok
tk|TR|Istanbul
uae|AE|Dubai
us-atl|US|Atlanta
us-chi-loc2|US|Chicago Loc2
us-chi|US|Chicago
us-dal|US|Dallas
us-dal-loc2|US|Dallas - Loc2
us-den|US|Denver
us-hou|US|Houston
us-la|US|LA
us-lv|US|Las Vegas
us-fl|US|Miami
us-nj|US|New Jersey
us-nj-loc2|US|New Jersey Loc2
us-ny|US|New York
us-slc|US|Salt Lake City
us-sf|US|San Francisco
us-sa|US|Seattle
ukr|UA|Kyiv
uk|GB|London
uk.man|GB|Manchester
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
        const area = comps[2];
        const hostname = `${id}.torguard.org`;
        const server = {
            serverId: id,
            hostname: hostname,
            supportedModuleTypes: [openVPN.moduleType]
        };
        const metadata = {
            providerId: providerId,
            countryCode: countryCode,
            categoryName: "Default",
            area: area
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
MIIDMTCCAhmgAwIBAgIJAKnGGJK6qLqSMA0GCSqGSIb3DQEBCwUAMBQxEjAQBgNV
BAMMCVRHLVZQTi1DQTAgFw0xOTA1MjExNDIzMTFaGA8yMDU5MDUxMTE0MjMxMVow
FDESMBAGA1UEAwwJVEctVlBOLUNBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEAlv0UgPD3xVAvhhP6q1HCmeAWbH+9HPkyQ2P6qM5oHY5dntjmq8YT48FZ
GHWv7+s9O47v6Bv7rEc4UwQx15cc2LByivX2JwmE8JACvNfwEnZXYAPq9WU3ZgRr
AGvA09ItuLqK2fQ4A7h8bFhmyxCbSzP1sSIT/zJY6ebuh5rDQSMJRMaoI0t1zorE
Z7PlEmh+o0w5GPs0D0vY50UcnEzB4GOdWC9pJREwEqppWYLN7RRdG8JyIqmA59mh
ARCnQFUo38HWic4trxFe71jtD7YInNV7ShQtg0S0sXo36Rqfz72Jo08qqI70dNs5
DN1aGNkQ/tRK9DhL5DLmTkaCw7mEFQIDAQABo4GDMIGAMB0GA1UdDgQWBBR7Dcym
XBp6u/jAaZOPUjUhEyhXfjBEBgNVHSMEPTA7gBR7DcymXBp6u/jAaZOPUjUhEyhX
fqEYpBYwFDESMBAGA1UEAwwJVEctVlBOLUNBggkAqcYYkrqoupIwDAYDVR0TBAUw
AwEB/zALBgNVHQ8EBAMCAQYwDQYJKoZIhvcNAQELBQADggEBAE79ngbdSlP7IBbf
nJ+2Ju7vqt9/GyhcsYtjibp6gsMUxKlD8HuvlSGj5kNO5wiwN7XXqsjYtJfdhmzz
VbXksi8Fnbnfa8GhFl4IAjLJ5cxaWOxjr6wx2AhIs+BVVARjaU7iTK91RXJnl6u7
UDHTkQylBTl7wgpMeG6GjhaHfcOL1t7D2w8x23cTO+p+n53P3cBq+9TiAUORdzXJ
vbCxlPMDSDArsgBjC57W7dtdnZo7gTfQG77JTDFBeSwPwLF7PjBB4S6rzU/4fcYw
y83XKP6zDn9tgUJDnpFb/7jJ/PbNkK4BWYJp3XytOtt66v9SEKw+v/fJ+VkjU16v
E/9Q3h4=
-----END CERTIFICATE-----
`;

    const tlsAuthKey = `
770e8de5fc56e0248cc7b5aab56be80d
0e19cbf003c1b3ed68efbaf08613c3a1
a019dac6a4b84f13a6198f73229ffc21
fa512394e288f82aa2cf0180f01fb3eb
1a71e00a077a20f6d7a83633f5b4f47f
27e30617eaf8485dd8c722a8606d56b3
c183f65da5d3c9001a8cbdb96c793d93
6251098b24fe52a6dd2472e98cfccbc4
66e63520d63ade7a0eacc36208c3142a
1068236a52142fbb7b3ed83d785e12a2
8261bccfb3bcb62a8d2f6d18f5df5f36
52e59c5627d8d9c8f7877c4d7b08e19a
5c363556ba68d392be78b75152dd55ba
0f74d45089e84f77f4492d886524ea6c
82b9f4dd83d46528d4f5c3b51cfeaf28
38d938bd0597c426b0e440434f2c451f
`;

    const tlsWrap = api.openVPNTLSWrap("crypt", tlsAuthKey);

    const cfg = {
        ca: ca,
        compressionFraming: 1,
        compressionAlgorithm: 1,
        keepAliveInterval: 5,
        keepAliveTimeout: 30,
        checksEKU: true
    };

    const cfgBasic = { ...cfg };
    cfgBasic.cipher = "AES-128-GCM";
    cfgBasic.digest = "SHA1";

    const cfgStrong = { ...cfg };
    cfgStrong.cipher = "AES-256-GCM";
    cfgStrong.digest = "SHA256";
    cfgStrong.tlsWrap = tlsWrap;

    const presetBasic = {
        providerId: providerId,
        presetId: presetIds.basic,
        description: "Basic",
        moduleType: moduleType,
        templateData: api.jsonToBase64({
            configuration: cfgBasic,
            endpoints: [
                "UDP:80",
                "UDP:443",
                "UDP:995",
                "TCP:80",
                "TCP:443",
                "TCP:995"
            ]
        })
    };
    const presetStrong = {
        providerId: providerId,
        presetId: presetIds.strong,
        description: "Strong",
        moduleType: moduleType,
        templateData: api.jsonToBase64({
            configuration: cfgStrong,
            endpoints: [
                "UDP:53",
                "UDP:501",
                "UDP:1198",
                "UDP:9201",
                "TCP:53",
                "TCP:501",
                "TCP:1198",
                "TCP:9201"
            ]
        })
    };

    return [presetBasic, presetStrong];
}
