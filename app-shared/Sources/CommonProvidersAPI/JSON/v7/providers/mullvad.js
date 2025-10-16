// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

const baseURL = "https://api.mullvad.net";

/*
 module = {
    authentication: {
        credentials: { username, password },
        token: { accessToken, expiryDate }
    }
 }
 options = {
    sessions: {
        device1: {
            privateKey: "",
            publicKey: "",
            peer: {
                id: "",
                creationDate: ...,
                addresses: []
            }
        },
        device2: { ... }
    }
 }
 session = { privateKey, publicKey, peer: { clientId, addresses } }
 */

function authenticate(module, deviceId) {
//    api.debug(`JS.authenticate: Module = ${JSON.stringify(module)}`);
    api.debug(`JS.authenticate: Device ID = ${deviceId}`);

    const newModule = module;

    // 1. Authenticate via credentials/token

    // Assert required input
    const auth = module.authentication;
    if (!auth) {
        return api.errorResponse("missing authentication");
    }

    // Check token validity
    if (auth.token) {
        const expiry = new Date(api.timestampToISO(auth.token.expiryDate));
        const now = new Date();
        api.debug(`JS.authenticate: Token expiry = ${expiry} (now: ${now})`);
        if (expiry > now) {
            api.debug("JS.authenticate: Token is valid");
        } else {
            api.debug("JS.authenticate: Token is expired");
            delete auth.token;
        }
    }

    // Authenticate if needed
    if (auth.token) {
        // Token is not expired, go ahead
    }
    // Token is expired, redo auth with credentials
    else if (auth.credentials) {
        api.debug("JS.authenticate: Authenticate with credentials");
        const body = api.jsonToBase64({
            "account_number": auth.credentials.username
        });
        const authURL = `${baseURL}/auth/v1/token`;
        const headers = {
            "Content-Type": "application/json"
        };
        const json = api.getResult("POST", authURL, headers, body);
        if (json.status != 200) {
            return api.httpErrorResponse(json.status, authURL);
        }
        api.debug(`JS.authenticate: Credentials are valid, response = ${json.response}`);
        const response = JSON.parse(json.response);
        auth.token = {
            accessToken: response.access_token,
            expiryDate: api.timestampFromISO(response.expiry)
        };
    }
    // Invalid token and missing credentials
    else {
        return api.errorResponse("authentication failed");
    }

    newModule.authentication = auth;
//    api.debug(`JS.authenticate: Module updated = ${JSON.stringify(newModule)}`);

    // 2. WireGuard session registration

    // No need to go further if module type is not WireGuard
    const wgType = "WireGuard";
    if (module.providerModuleType != wgType) {
        return {
            response: newModule
        };
    }

    const rawOptions = module.moduleOptions[wgType];
    if (!rawOptions) {
        return api.errorResponse("missing options");
    }
    const storage = api.jsonFromBase64(rawOptions);
    if (!storage) {
        return api.errorResponse("corrupt storage");
    }
    const session = storage.sessions[deviceId];
    if (!session) {
        return api.errorResponse("missing session");
    }

//    api.debug(`JS.authenticate: Auth = ${JSON.stringify(auth))}`);
//    api.debug(`JS.authenticate: Storage = ${JSON.stringify(storage))}`);
//    api.debug(`JS.authenticate: Session = ${JSON.stringify(session))}`);
    if (session.peer) {
        api.debug(`JS.authenticate: Session peer = ${JSON.stringify(session.peer)}`);
    }

    // If subsequent calls return 401, rather than re-authenticating, just
    // fail and inform the user. This should be rare and managing a potentially
    // infinite auth loop is really not worth the deal.

    // Authenticate with token from now on
    const headers = {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${auth.token.accessToken}`
    };

    // Get list of all registered devices
    const devicesURL = `${baseURL}/accounts/v1/devices`;
    const json = api.getResult("GET", devicesURL, headers);
    if (json.status != 200) {
        return api.httpErrorResponse(json.status, devicesURL);
    }
    api.debug(`JS.authenticate: Devices = ${json.response}`);
    api.debug(`JS.authenticate: Session public key = ${session.publicKey}`);
    const devices = JSON.parse(json.response);

    // Look up registered device by peer ID
    let myDevice = devices.find(d => session.peer && d.id == session.peer.id);
    if (myDevice) {
        api.debug(`JS.authenticate: Device found = ${JSON.stringify(myDevice)}`);

        // Public key differs, replace remote key with local
        if (myDevice.pubkey != session.publicKey) {
            api.debug(`JS.authenticate: Update public key from '${myDevice.pubkey}' to '${session.publicKey}'`);
            const body = api.jsonToBase64({
                "pubkey": session.publicKey
            });
            const putDeviceURL = `${baseURL}/accounts/v1/devices/${myDevice.id}/pubkey`;
            const json = api.getResult("PUT", putDeviceURL, headers, body);
            if (json.status != 200) {
                return api.httpErrorResponse(json.status, putDeviceURL);
            }
            api.debug(`JS.authenticate: Device updated = ${json.response}`);
            myDevice = JSON.parse(json.response);
        }
        // The public key is up-to-date, refresh local
        else {
            api.debug("JS.authenticate: Public key is up to date");
        }
    }
    // Peer not found, register as new device
    else {
        api.debug(`JS.authenticate: Device not found, register with public key '${session.publicKey}'`);
        const body = api.jsonToBase64({
            "pubkey": session.publicKey
        });

        // WARNING: Fails with HTTP 400 if:
        //
        // - publicKey is used by another device
        // - publicKey is used by a device that was recently deleted
        //
        const json = api.getResult("POST", devicesURL, headers, body);
        if (json.status != 201) {
            return api.httpErrorResponse(json.status, devicesURL);
        }
        api.debug(`JS.authenticate: Device created = ${json.response}`);
        myDevice = JSON.parse(json.response);
    }

    // Update storage
    const peer = {
        id: myDevice.id,
        creationDate: api.timestampFromISO(myDevice.created),
        addresses: []
    };
    if (myDevice.ipv4_address) {
        peer.addresses.push(myDevice.ipv4_address);
    }
    if (myDevice.ipv6_address) {
        peer.addresses.push(myDevice.ipv6_address);
    }
    session.peer = peer;
    storage.sessions[deviceId] = session;
    api.debug(`JS.authenticate: Session updated = ${JSON.stringify(session)}`);
    api.debug(`JS.authenticate: Storage updated = ${JSON.stringify(storage)}`);

    newModule.moduleOptions[wgType] = api.jsonToBase64(storage);
//    api.debug(`JS.authenticate: Module updated = ${JSON.stringify(newModule)}`);

    return {
        response: newModule
    };
}

function getInfrastructure(module, headers) {
    const providerId = "mullvad";
    const openVPN = {
        moduleType: "OpenVPN",
        presetIds: {
            recommended: "default",
            dnsOverride: "dns"
        }
    };
    const wireGuard = {
        moduleType: "WireGuard",
        presetIds: {
            recommended: "default"
        }
    };

    const json = api.getJSON(`${baseURL}/app/v1/relays`, headers);
    if (!json.response) {
        return json;
    }

    const locations = json.response.locations;
    const servers = [];

    // The following code relies on OpenVPN/WireGuard servers not
    // overlapping. Each server is either OpenVPN or WireGuard, but
    // not both.
    const processRelay = function(relay, moduleType) {
        if (!relay.active) return;
        if (moduleType == wireGuard.moduleType && !relay.public_key) return;

        const location = locations[relay.location];
        if (!location) return;

        const id = relay.hostname;
        const hostname = `${id.toLowerCase()}.mullvad.net`;
        const addresses = [
            relay.ipv4_addr_in,
//            relay.ipv6_addr_in // FIXME: ###, IPv6 encoding?
        ].map((a) => api.ipV4ToBase64(a));

        const code = id.split("-")[0].toUpperCase();
        const area = location.city;
        const num = parseInt(id.split("-").pop(), 10);

        const server = {
            serverId: id,
            hostname: hostname,
            ipAddresses: addresses,
            supportedModuleTypes: [moduleType]
        };
        if (relay.public_key) {
            server.userInfo = {
                "wgPublicKey": relay.public_key
            };
        }
        const metadata = {
            providerId: providerId,
            categoryName: "Default",
            countryCode: code
        };
        metadata.area = area;
        metadata.num = num;
        server.metadata = metadata;

        servers.push(server);
    };
    json.response.openvpn.relays.forEach((relay) => {
        processRelay(relay, openVPN.moduleType);
    });
    json.response.wireguard.relays.forEach((relay) => {
        processRelay(relay, wireGuard.moduleType);
    })

    const ovpnPresets = getOpenVPNPresets(providerId, openVPN.moduleType,
                                          openVPN.presetIds, json.response.openvpn.ports);
    const wgPresets = getWireGuardPresets(providerId, wireGuard.moduleType,
                                          wireGuard.presetIds);
    const presets = ovpnPresets.concat(wgPresets);

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
-----END CERTIFICATE-----
`;

    const cfg = {
        ca: ca,
        cipher: "AES-256-CBC",
        digest: "SHA1",
        compressionFraming: 0,
        keepAliveInterval: 10,
        keepAliveTimeout: 60,
        renegotiatesAfter: 0,
        checksEKU: true,
    };

    const endpoints = ports.map(p =>
        `${p.protocol.toUpperCase()}:${p.port}`
    );

    const recommended = {
        providerId: providerId,
        presetId: presetIds.recommended,
        description: "Default",
        moduleType: moduleType,
        templateData: api.jsonToBase64({
            configuration: cfg,
            endpoints: endpoints
        })
    };

    const dnsOverride = {
        providerId: providerId,
        presetId: presetIds.dnsOverride,
        description: "Custom DNS",
        moduleType: moduleType,
        templateData: api.jsonToBase64({
            configuration: cfg,
            endpoints: ["UDP:1400", "TCP:1401"],
        })
    };

    return [recommended, dnsOverride];
}

// MARK: WireGuard

function getWireGuardPresets(providerId, moduleType, presetIds) {
    const recommended = {
        providerId: providerId,
        presetId: presetIds.recommended,
        description: "Default",
        moduleType: moduleType,
        templateData: api.jsonToBase64({
            ports: [51820]
        })
    };
    return [recommended];
}
