// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

function getInfrastructure(module, headers) {
    const providerId = "vyprvpn";
    const openVPN = {
        moduleType: "OpenVPN",
        presetIds: {
            recommended: "default"
        }
    };

    // XXX: hardcoded servers
    // https://support.vyprvpn.com/hc/en-us/articles/360037728912-What-are-the-VyprVPN-server-addresses-
    const countriesCSV = `
ae1|AE|Dubai
ar1|AR|Buenos Aires
at1|AT|Vienna
au1|AU|Sydney
au2|AU|Melbourne
au3|AU|Perth
be1|BE|Brussels
bg1|BG|Sofia
bh1|BH|Manama
br1|BR|São Paulo
ca1|CA|Toronto
ch1|CH|Zurich
co1|CO|Bogotá
cr1|CR|San José
cz1|CZ|Prague
de1|DE|Frankfurt
dk1|DK|Copenhagen
dz1|DZ|Algiers
eg1|EG|Cairo
es1|ES|Madrid
eu1|EU|Amsterdam
fi1|FI|Helsinki
fr1|FR|Paris
gr1|GR|Athens
hk1|HK|Hong Kong
id1|ID|Jakarta
ie1|IE|Dublin
il1|IL|Tel Aviv
in1|IN|Mumbai
is1|IS|Reykjavík
it1|IT|Rome
jp1|JP|Tokyo
kr1|KR|Seoul
li1|LI|Schaan
lt1|LT|Vilnius
lu1|LU|Luxembourg City
lv1|LV|Riga
mh1|MH|Majuro
mo1|MO|Macau
mv1|MV|Malé
mx1|MX|Mexico City
my1|MY|Kuala Lumpur
no1|NO|Oslo
nz1|NZ|Auckland
pa1|PA|Panama City
ph1|PH|Manila
pk1|PK|Karachi
pl1|PL|Warsaw
pt1|PT|Lisbon
qa1|QA|Doha
ro1|RO|Bucharest
ru1|RU|Moscow
sa1|SA|Riyadh
se1|SE|Stockholm
sg1|SG|Singapore
si1|SI|Ljubljana
sk1|SK|Bratislava
sv1|SV|San Salvador
th1|TH|Bangkok
tr1|TR|Istanbul
tw1|TW|Taipei
ua1|UA|Kiev
uk1|GB|London
us1|US|Los Angeles, CA
us2|US|Washington, DC
us3|US|Austin, TX
us4|US|Miami, FL
us5|US|New York City, NY
us6|US|Chicago, IL
us7|US|San Francisco, CA
us8|US|Seattle, WA
uy1|UY|Montevideo
vn1|VN|Hanoi
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
        const hostname = `${id}.vyprvpn.com`;
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
MIIGDjCCA/agAwIBAgIJAL2ON5xbane/MA0GCSqGSIb3DQEBDQUAMIGTMQswCQYD
VQQGEwJDSDEQMA4GA1UECAwHTHVjZXJuZTEPMA0GA1UEBwwGTWVnZ2VuMRkwFwYD
VQQKDBBHb2xkZW4gRnJvZyBHbWJIMSEwHwYDVQQDDBhHb2xkZW4gRnJvZyBHbWJI
IFJvb3QgQ0ExIzAhBgkqhkiG9w0BCQEWFGFkbWluQGdvbGRlbmZyb2cuY29tMB4X
DTE5MTAxNzIwMTQxMFoXDTM5MTAxMjIwMTQxMFowgZMxCzAJBgNVBAYTAkNIMRAw
DgYDVQQIDAdMdWNlcm5lMQ8wDQYDVQQHDAZNZWdnZW4xGTAXBgNVBAoMEEdvbGRl
biBGcm9nIEdtYkgxITAfBgNVBAMMGEdvbGRlbiBGcm9nIEdtYkggUm9vdCBDQTEj
MCEGCSqGSIb3DQEJARYUYWRtaW5AZ29sZGVuZnJvZy5jb20wggIiMA0GCSqGSIb3
DQEBAQUAA4ICDwAwggIKAoICAQCtuddaZrpWZ+nUuJpG+ohTquO3XZtq6d4U0E2o
iPeIiwm+WWLY49G+GNJb5aVrlrBojaykCAc2sU6NeUlpg3zuqrDqLcz7PAE4OdNi
OdrLBF1o9ZHrcITDZN304eAY5nbyHx5V6x/QoDVCi4g+5OVTA+tZjpcl4wRIpgkn
WznO73IKCJ6YckpLn1BsFrVCb2ehHYZLg7Js58FzMySIxBmtkuPeHQXL61DFHh3c
TFcMxqJjzh7EGsWRyXfbAaBGYnT+TZwzpLXXt8oBGpNXG8YBDrPdK0A+lzMnJ4nS
0rgHDSRF0brx+QYk/6CgM510uFzB7zytw9UTD3/5TvKlCUmTGGgI84DbJ3DEvjxb
giQnJXCUZKKYSHwrK79Y4Qn+lXu4Bu0ZTCJBje0GUVMTPAvBCeDvzSe0iRcVSNMJ
VM68d4kD1PpSY/zWfCz5hiOjHWuXinaoZ0JJqRF8kGbJsbDlDYDtVvh/Cd4aWN6Q
/2XLpszBsG5i8sdkS37nzkdlRwNEIZwsKfcXwdTOlDinR1LUG68LmzJAwfNE47xb
rZUsdGGfG+HSPsrqFFiLGe7Y4e2+a7vGdSY9qR9PAzyx0ijCCrYzZDIsb2dwjLct
Ux6a3LNV8cpfhKX+s6tfMldGufPI7byHT1Ybf0NtMS1d1RjD6IbqedXQdCKtaw68
kTX//wIDAQABo2MwYTAdBgNVHQ4EFgQU2EbQvBd1r/EADr2jCPMXsH7zEXEwHwYD
VR0jBBgwFoAU2EbQvBd1r/EADr2jCPMXsH7zEXEwDwYDVR0TAQH/BAUwAwEB/zAO
BgNVHQ8BAf8EBAMCAYYwDQYJKoZIhvcNAQENBQADggIBAAViCPieIronV+9asjZy
o5oSZSNWUkWRYdezjezsf49+fwT12iRgnkSEQeoj5caqcOfNm/eRpN4G7jhhCcxy
9RGF+GurIlZ4v0mChZbx1jcxqr9/3/Z2TqvHALyWngBYDv6pv1iWcd9a4+QL9kj1
Tlp8vUDIcHMtDQkEHnkhC+MnjyrdsdNE5wjlLljjFR2Qy5a6/kWwZ1JQVYof1J1E
zY6mU7YLMHOdjfmeci5i0vg8+9kGMsc/7Wm69L1BeqpDB3ZEAgmOtda2jwOevJ4s
ABmRoSThFp4DeMcxb62HW1zZCCpgzWv/33+pZdPvnZHSz7RGoxH4Ln7eBf3oo2PM
lu7wCsid3HUdgkRf2Og1RJIrFfEjb7jga1JbKX2Qo/FH3txzdUimKiDRv3ccFmEO
qjndUG6hP+7/EsI43oCPYOvZR+u5GdOkhYrDGZlvjXeJ1CpQxTR/EX+Vt7F8YG+i
2LkO7lhPLb+LzgPAxVPCcEMHruuUlE1BYxxzRMOW4X4kjHvJjZGISxa9lgTY3e0m
noQNQVBHKfzI2vGLwvcrFcCIrVxeEbj2dryfByyhZlrNPFbXyf7P4OSfk+fVh6Is
1IF1wksfLY/6gWvcmXB8JwmKFDa9s5NfzXnzP3VMrNUWXN3G8Eee6qzKKTDsJ70O
rgAx9j9a+dMLfe1vP5t6GQj5
-----END CERTIFICATE-----
`;

    const cfg = {
        ca: ca,
        cipher: "AES-256-GCM",
        digest: "SHA1",
        compressionFraming: 1,
        compressionAlgorithm: 1,
        keepAliveSeconds: 10,
        keepAliveTimeoutSeconds: 60,
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
                "UDP:443"
            ]
        })
    };

    return [recommended]
}
