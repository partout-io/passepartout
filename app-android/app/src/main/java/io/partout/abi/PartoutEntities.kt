package io.partout.abi

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable


@Serializable
@SerialName("IPSettings")
data class IPSettings(
    val subnets: List<Subnet>,
    val legacySingleSubnet: Subnet? = null,
    val includedRoutes: List<Route>,
    val excludedRoutes: List<Route>,
)

@Serializable
@SerialName("SocketType")
enum class SocketType {
    udp,
    tcp,
}

@Serializable
@SerialName("IPSocketType")
enum class IPSocketType {
    udp,
    tcp,
    udp4,
    tcp4,
    udp6,
    tcp6,
}

@Serializable
@SerialName("Route")
data class Route(
    val destination: Subnet? = null,
    val gateway: Address? = null,
)

@Serializable
@SerialName("IPModule")
data class IPModule(
    val id: String,
    val ipv4: IPSettings? = null,
    val ipv6: IPSettings? = null,
    val mtu: Int? = null,
)

@Serializable
@SerialName("HTTPProxyModule")
data class HTTPProxyModule(
    val id: String,
    val proxy: Endpoint? = null,
    val secureProxy: Endpoint? = null,
    val pacURL: String? = null,
    val bypassDomains: List<Address>,
)

@Serializable
@SerialName("DNSProtocol")
enum class DNSProtocol {
    cleartext,
    https,
    tls,
}

@Serializable
@SerialName("OnDemandModule")
data class OnDemandModule(
    val id: String,
    val policy: OnDemandModule_Policy,
    val withSSIDs: Map<String, Boolean>,
    val withOtherNetworks: Set<OnDemandModule_OtherNetwork>,
)

@Serializable
@SerialName("OnDemandModule_Policy")
enum class OnDemandModule_Policy {
    any,
    including,
    excluding,
}

@Serializable
@SerialName("OnDemandModule_OtherNetwork")
enum class OnDemandModule_OtherNetwork {
    mobile,
    ethernet,
}

@Serializable
@SerialName("DNSModule")
data class DNSModule(
    val id: String,
    val protocolType: DNSModule_ProtocolType,
    val servers: List<Address>,
    val domainName: Address? = null,
    val searchDomains: List<Address>? = null,
    val routesThroughVPN: Boolean? = null,
)

@Serializable
@SerialName("DNSModule_ProtocolType")
enum class DNSModule_ProtocolType {
    cleartext,
    https,
    tls,
}

@Serializable
@SerialName("ProfileBehavior")
data class ProfileBehavior(
    val disconnectsOnSleep: Boolean,
    val includesAllNetworks: Boolean? = null,
)

@Serializable
@SerialName("OpenVPNModule")
data class OpenVPNModule(
    val id: String,
    val configuration: OpenVPN_Configuration? = null,
    val credentials: OpenVPN_Credentials? = null,
    val requiresInteractiveCredentials: Boolean? = null,
)

@Serializable
@SerialName("OpenVPN_CryptoContainer")
data class OpenVPN_CryptoContainer(
    val pem: String,
)

@Serializable
@SerialName("OpenVPN_TLSWrap")
data class OpenVPN_TLSWrap(
    val strategy: OpenVPN_TLSWrap_Strategy,
    val key: OpenVPN_StaticKey,
)

@Serializable
@SerialName("OpenVPN_TLSWrap_Strategy")
enum class OpenVPN_TLSWrap_Strategy {
    auth,
    crypt,
}

@Serializable
@SerialName("OpenVPN_ObfuscationMethod")
enum class OpenVPN_ObfuscationMethod {
    xormask,
    xorptrpos,
    reverse,
    obfuscate,
}

@Serializable
@SerialName("OpenVPN_CompressionAlgorithm")
enum class OpenVPN_CompressionAlgorithm {
    disabled,
    LZO,
    other,
}

@Serializable
@SerialName("OpenVPN_CompressionFraming")
enum class OpenVPN_CompressionFraming {
    disabled,
    compLZO,
    compress,
    compressV2,
}

@Serializable
@SerialName("OpenVPN_StaticKey")
data class OpenVPN_StaticKey(
    val secureData: ByteArray,
    val direction: OpenVPN_StaticKey_Direction? = null,
)

@Serializable
@SerialName("OpenVPN_StaticKey_Direction")
enum class OpenVPN_StaticKey_Direction {
    server,
    client,
}

@Serializable
@SerialName("OpenVPN_Credentials")
data class OpenVPN_Credentials(
    val username: String,
    val password: String,
    val otpMethod: OpenVPN_Credentials_OTPMethod,
    val otp: String? = null,
)

@Serializable
@SerialName("OpenVPN_Credentials_OTPMethod")
enum class OpenVPN_Credentials_OTPMethod {
    none,
    append,
    encode,
}

@Serializable
@SerialName("OpenVPN_Cipher")
enum class OpenVPN_Cipher {
    aes128cbc,
    aes192cbc,
    aes256cbc,
    aes128gcm,
    aes192gcm,
    aes256gcm,
}

@Serializable
@SerialName("OpenVPN_Digest")
enum class OpenVPN_Digest {
    sha1,
    sha224,
    sha256,
    sha384,
    sha512,
}

@Serializable
@SerialName("OpenVPN_RoutingPolicy")
enum class OpenVPN_RoutingPolicy {
    IPv4,
    IPv6,
    blockLocal,
}

@Serializable
@SerialName("OpenVPN_PullMask")
enum class OpenVPN_PullMask {
    routes,
    dns,
    proxy,
}

@Serializable
@SerialName("OpenVPN_Configuration")
data class OpenVPN_Configuration(
    val cipher: OpenVPN_Cipher? = null,
    val dataCiphers: List<OpenVPN_Cipher>? = null,
    val digest: OpenVPN_Digest? = null,
    val compressionFraming: OpenVPN_CompressionFraming? = null,
    val compressionAlgorithm: OpenVPN_CompressionAlgorithm? = null,
    val ca: OpenVPN_CryptoContainer? = null,
    val clientCertificate: OpenVPN_CryptoContainer? = null,
    val clientKey: OpenVPN_CryptoContainer? = null,
    val tlsWrap: OpenVPN_TLSWrap? = null,
    val tlsSecurityLevel: Int? = null,
    val keepAliveInterval: Double? = null,
    val keepAliveTimeout: Double? = null,
    val renegotiatesAfter: Double? = null,
    val remotes: List<ExtendedEndpoint>? = null,
    val checksEKU: Boolean? = null,
    val checksSANHost: Boolean? = null,
    val sanHost: String? = null,
    val randomizeEndpoint: Boolean? = null,
    val randomizeHostnames: Boolean? = null,
    val usesPIAPatches: Boolean? = null,
    val mtu: Int? = null,
    val authUserPass: Boolean? = null,
    val staticChallenge: Boolean? = null,
    val authToken: String? = null,
    val peerId: UInt? = null,
    val ipv4: IPSettings? = null,
    val ipv6: IPSettings? = null,
    val routes4: List<Route>? = null,
    val routes6: List<Route>? = null,
    val routeGateway4: Address? = null,
    val routeGateway6: Address? = null,
    val dnsServers: List<String>? = null,
    val dnsDomain: String? = null,
    val searchDomains: List<String>? = null,
    val httpProxy: Endpoint? = null,
    val httpsProxy: Endpoint? = null,
    val proxyAutoConfigurationURL: String? = null,
    val proxyBypassDomains: List<String>? = null,
    val routingPolicies: List<OpenVPN_RoutingPolicy>? = null,
    val noPullMask: List<OpenVPN_PullMask>? = null,
    val xorMethod: OpenVPN_ObfuscationMethod? = null,
)

@Serializable
@SerialName("WireGuard_RemoteInterface")
data class WireGuard_RemoteInterface(
    val publicKey: WireGuard_Key,
    val preSharedKey: WireGuard_Key? = null,
    val endpoint: Endpoint? = null,
    val allowedIPs: List<Subnet>,
    val keepAlive: UInt? = null,
)

@Serializable
@SerialName("WireGuard_Configuration")
data class WireGuard_Configuration(
    val `interface`: WireGuard_LocalInterface,
    val peers: List<WireGuard_RemoteInterface>,
)

@Serializable
@SerialName("WireGuard_LocalInterface")
data class WireGuard_LocalInterface(
    val privateKey: WireGuard_Key,
    val addresses: List<Subnet>,
    val dns: DNSModule? = null,
    val mtu: UInt? = null,
)

@Serializable
@SerialName("WireGuardModule")
data class WireGuardModule(
    val id: String,
    val configuration: WireGuard_Configuration? = null,
)

typealias Address = String

typealias EndpointProtocol = String

typealias Subnet = String

typealias ExtendedEndpoint = String

typealias Endpoint = String

typealias ModuleType = String

typealias WireGuard_Key = String

