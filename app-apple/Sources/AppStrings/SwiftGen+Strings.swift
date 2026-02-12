// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum Strings {
  public enum Alerts {
    public enum Import {
      public enum Passphrase {
        /// Enter passphrase for '%@'.
        public static func message(_ p1: Any) -> String {
          return Strings.tr("Localizable", "alerts.import.passphrase.message", String(describing: p1), fallback: "Enter passphrase for '%@'.")
        }
        /// Decrypt
        public static let ok = Strings.tr("Localizable", "alerts.import.passphrase.ok", fallback: "Decrypt")
      }
    }
    public enum Providers {
      public enum MissingServer {
        /// No provider server selected. Please select a destination server on your iOS/macOS device.
        public static let message = Strings.tr("Localizable", "alerts.providers.missing_server.message", fallback: "No provider server selected. Please select a destination server on your iOS/macOS device.")
      }
    }
  }
  public enum Entities {
    public enum Dns {
      /// Search domains
      public static let searchDomains = Strings.tr("Localizable", "entities.dns.search_domains", fallback: "Search domains")
      /// Servers
      public static let servers = Strings.tr("Localizable", "entities.dns.servers", fallback: "Servers")
    }
    public enum DnsProtocol {
      /// Cleartext
      public static let cleartext = Strings.tr("Localizable", "entities.dns_protocol.cleartext", fallback: "Cleartext")
      /// Over HTTPS
      public static let https = Strings.tr("Localizable", "entities.dns_protocol.https", fallback: "Over HTTPS")
      /// Over TLS
      public static let tls = Strings.tr("Localizable", "entities.dns_protocol.tls", fallback: "Over TLS")
    }
    public enum HttpProxy {
      /// Bypass domains
      public static let bypassDomains = Strings.tr("Localizable", "entities.http_proxy.bypass_domains", fallback: "Bypass domains")
    }
    public enum OnDemand {
      public enum Policy {
        /// All networks
        public static let any = Strings.tr("Localizable", "entities.on_demand.policy.any", fallback: "All networks")
        /// Excluding
        public static let excluding = Strings.tr("Localizable", "entities.on_demand.policy.excluding", fallback: "Excluding")
        /// Including
        public static let including = Strings.tr("Localizable", "entities.on_demand.policy.including", fallback: "Including")
      }
    }
    public enum Openvpn {
      public enum CompressionAlgorithm {
        /// Unsupported
        public static let other = Strings.tr("Localizable", "entities.openvpn.compression_algorithm.other", fallback: "Unsupported")
      }
      public enum OtpMethod {
        /// Append
        public static let append = Strings.tr("Localizable", "entities.openvpn.otp_method.append", fallback: "Append")
        /// Encode
        public static let encode = Strings.tr("Localizable", "entities.openvpn.otp_method.encode", fallback: "Encode")
        /// None
        public static let `none` = Strings.tr("Localizable", "entities.openvpn.otp_method.none", fallback: "None")
      }
    }
    public enum TunnelStatus {
      /// Activating
      public static let activating = Strings.tr("Localizable", "entities.tunnel_status.activating", fallback: "Activating")
      /// Active
      public static let active = Strings.tr("Localizable", "entities.tunnel_status.active", fallback: "Active")
      /// Deactivating
      public static let deactivating = Strings.tr("Localizable", "entities.tunnel_status.deactivating", fallback: "Deactivating")
      /// Inactive
      public static let inactive = Strings.tr("Localizable", "entities.tunnel_status.inactive", fallback: "Inactive")
    }
    public enum Ui {
      public enum ConfigFlag {
        /// Modern TCP
        public static let neSocketTCP = Strings.tr("Localizable", "entities.ui.config_flag.neSocketTCP", fallback: "Modern TCP")
        /// Modern UDP
        public static let neSocketUDP = Strings.tr("Localizable", "entities.ui.config_flag.neSocketUDP", fallback: "Modern UDP")
        /// Cross-platform OpenVPN
        public static let ovpnCrossConnection = Strings.tr("Localizable", "entities.ui.config_flag.ovpnCrossConnection", fallback: "Cross-platform OpenVPN")
        /// Cross-platform WireGuard
        public static let wgCrossConnection = Strings.tr("Localizable", "entities.ui.config_flag.wgCrossConnection", fallback: "Cross-platform WireGuard")
      }
      public enum SystemAppearance {
        /// Dark
        public static let dark = Strings.tr("Localizable", "entities.ui.system_appearance.dark", fallback: "Dark")
        /// Light
        public static let light = Strings.tr("Localizable", "entities.ui.system_appearance.light", fallback: "Light")
        /// System
        public static let system = Strings.tr("Localizable", "entities.ui.system_appearance.system", fallback: "System")
      }
    }
  }
  public enum Errors {
    public enum App {
      /// Unable to complete operation.
      public static let `default` = Strings.tr("Localizable", "errors.app.default", fallback: "Unable to complete operation.")
      /// Unable to duplicate profile '%@'.
      public static func duplicate(_ p1: Any) -> String {
        return Strings.tr("Localizable", "errors.app.duplicate", String(describing: p1), fallback: "Unable to duplicate profile '%@'.")
      }
      /// Unable to fetch products, please retry later.
      public static let emptyProducts = Strings.tr("Localizable", "errors.app.empty_products", fallback: "Unable to fetch products, please retry later.")
      /// Profile name is empty.
      public static let emptyProfileName = Strings.tr("Localizable", "errors.app.empty_profile_name", fallback: "Profile name is empty.")
      /// Unable to import profiles.
      public static let `import` = Strings.tr("Localizable", "errors.app.import", fallback: "Unable to import profiles.")
      /// Module %@ is malformed. %@
      public static func malformedModule(_ p1: Any, _ p2: Any) -> String {
        return Strings.tr("Localizable", "errors.app.malformed_module", String(describing: p1), String(describing: p2), fallback: "Module %@ is malformed. %@")
      }
      /// The %@ module requires an active connection among the following types: %@
      public static func moduleRequiresConnection(_ p1: Any, _ p2: Any) -> String {
        return Strings.tr("Localizable", "errors.app.module_requires_connection", String(describing: p1), String(describing: p2), fallback: "The %@ module requires an active connection among the following types: %@")
      }
      /// Permission denied
      public static let permissionDenied = Strings.tr("Localizable", "errors.app.permission_denied", fallback: "Permission denied")
      /// Unable to execute operation.
      public static let tunnel = Strings.tr("Localizable", "errors.app.tunnel", fallback: "Unable to execute operation.")
      /// Unable to start the import. Make sure that your TV is properly connected to the local network.
      public static let webReceiver = Strings.tr("Localizable", "errors.app.web_receiver", fallback: "Unable to start the import. Make sure that your TV is properly connected to the local network.")
      public enum Partout {
        /// Unable to connect to provider server (reason=%@).
        public static func corruptProviderModule(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.app.partout.corrupt_provider_module", String(describing: p1), fallback: "Unable to connect to provider server (reason=%@).")
        }
        /// Unable to complete operation (code=%@).
        public static func `default`(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.app.partout.default", String(describing: p1), fallback: "Unable to complete operation (code=%@).")
        }
        /// Some active modules are incompatible, try to only activate one of them.
        public static let incompatibleModules = Strings.tr("Localizable", "errors.app.partout.incompatible_modules", fallback: "Some active modules are incompatible, try to only activate one of them.")
        /// Please finish the configuration of the %@ module.
        public static func incompleteModule(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.app.partout.incomplete_module", String(describing: p1), fallback: "Please finish the configuration of the %@ module.")
        }
        /// Invalid fields.
        public static let invalidFields = Strings.tr("Localizable", "errors.app.partout.invalid_fields", fallback: "Invalid fields.")
        /// No server selected in provider.
        public static let missingProviderEntity = Strings.tr("Localizable", "errors.app.partout.missing_provider_entity", fallback: "No server selected in provider.")
        /// The profile has no active modules.
        public static let noActiveModules = Strings.tr("Localizable", "errors.app.partout.no_active_modules", fallback: "The profile has no active modules.")
        /// Unable to parse file.
        public static let parsing = Strings.tr("Localizable", "errors.app.partout.parsing", fallback: "Unable to parse file.")
        /// The operation timed out.
        public static let timeout = Strings.tr("Localizable", "errors.app.partout.timeout", fallback: "The operation timed out.")
      }
    }
    public enum Tunnel {
      /// Auth failed
      public static let auth = Strings.tr("Localizable", "errors.tunnel.auth", fallback: "Auth failed")
      /// Compression unsupported
      public static let compression = Strings.tr("Localizable", "errors.tunnel.compression", fallback: "Compression unsupported")
      /// DNS failed
      public static let dns = Strings.tr("Localizable", "errors.tunnel.dns", fallback: "DNS failed")
      /// Encryption failed
      public static let encryption = Strings.tr("Localizable", "errors.tunnel.encryption", fallback: "Encryption failed")
      /// Failed
      public static let generic = Strings.tr("Localizable", "errors.tunnel.generic", fallback: "Failed")
      /// Purchase required
      public static let ineligible = Strings.tr("Localizable", "errors.tunnel.ineligible", fallback: "Purchase required")
      /// Missing routing
      public static let routing = Strings.tr("Localizable", "errors.tunnel.routing", fallback: "Missing routing")
      /// Server shutdown
      public static let shutdown = Strings.tr("Localizable", "errors.tunnel.shutdown", fallback: "Server shutdown")
      /// TLS failed
      public static let tls = Strings.tr("Localizable", "errors.tunnel.tls", fallback: "TLS failed")
    }
    public enum Wireguard {
      public enum Interface {
        /// Interface addresses must be a list of comma-separated IP addresses, optionally in CIDR notation
        public static let messageAddressInvalid = Strings.tr("Localizable", "errors.wireguard.interface.MessageAddressInvalid", fallback: "Interface addresses must be a list of comma-separated IP addresses, optionally in CIDR notation")
        /// Interface’s DNS servers must be a list of comma-separated IP addresses
        public static let messageDNSInvalid = Strings.tr("Localizable", "errors.wireguard.interface.MessageDNSInvalid", fallback: "Interface’s DNS servers must be a list of comma-separated IP addresses")
        /// Interface’s listen port must be between 0 and 65535, or unspecified
        public static let messageListenPortInvalid = Strings.tr("Localizable", "errors.wireguard.interface.MessageListenPortInvalid", fallback: "Interface’s listen port must be between 0 and 65535, or unspecified")
        /// Interface’s MTU must be between 576 and 65535, or unspecified
        public static let messageMTUInvalid = Strings.tr("Localizable", "errors.wireguard.interface.MessageMTUInvalid", fallback: "Interface’s MTU must be between 576 and 65535, or unspecified")
        /// Interface name is required
        public static let messageNameRequired = Strings.tr("Localizable", "errors.wireguard.interface.MessageNameRequired", fallback: "Interface name is required")
        /// Interface’s private key must be a 32-byte key in base64 encoding
        public static let messagePrivateKeyInvalid = Strings.tr("Localizable", "errors.wireguard.interface.MessagePrivateKeyInvalid", fallback: "Interface’s private key must be a 32-byte key in base64 encoding")
        /// Interface’s private key is required
        public static let messagePrivateKeyRequired = Strings.tr("Localizable", "errors.wireguard.interface.MessagePrivateKeyRequired", fallback: "Interface’s private key is required")
        /// Invalid interface
        public static let title = Strings.tr("Localizable", "errors.wireguard.interface.Title", fallback: "Invalid interface")
      }
      public enum Peer {
        /// Peer’s allowed IPs must be a list of comma-separated IP addresses, optionally in CIDR notation
        public static let messageAllowedIPsInvalid = Strings.tr("Localizable", "errors.wireguard.peer.MessageAllowedIPsInvalid", fallback: "Peer’s allowed IPs must be a list of comma-separated IP addresses, optionally in CIDR notation")
        /// Peer’s endpoint must be of the form ‘host:port’ or ‘[host]:port’
        public static let messageEndpointInvalid = Strings.tr("Localizable", "errors.wireguard.peer.MessageEndpointInvalid", fallback: "Peer’s endpoint must be of the form ‘host:port’ or ‘[host]:port’")
        /// Peer’s persistent keepalive must be between 0 to 65535, or unspecified
        public static let messagePersistentKeepaliveInvalid = Strings.tr("Localizable", "errors.wireguard.peer.MessagePersistentKeepaliveInvalid", fallback: "Peer’s persistent keepalive must be between 0 to 65535, or unspecified")
        /// Peer’s preshared key must be a 32-byte key in base64 encoding
        public static let messagePreSharedKeyInvalid = Strings.tr("Localizable", "errors.wireguard.peer.MessagePreSharedKeyInvalid", fallback: "Peer’s preshared key must be a 32-byte key in base64 encoding")
        /// Two or more peers cannot have the same public key
        public static let messagePublicKeyDuplicated = Strings.tr("Localizable", "errors.wireguard.peer.MessagePublicKeyDuplicated", fallback: "Two or more peers cannot have the same public key")
        /// Peer’s public key must be a 32-byte key in base64 encoding
        public static let messagePublicKeyInvalid = Strings.tr("Localizable", "errors.wireguard.peer.MessagePublicKeyInvalid", fallback: "Peer’s public key must be a 32-byte key in base64 encoding")
        /// Peer’s public key is required
        public static let messagePublicKeyRequired = Strings.tr("Localizable", "errors.wireguard.peer.MessagePublicKeyRequired", fallback: "Peer’s public key is required")
        /// Invalid peer
        public static let title = Strings.tr("Localizable", "errors.wireguard.peer.Title", fallback: "Invalid peer")
      }
      public enum Title {
        /// Address ‘%@’ is invalid.
        public static func addressInvalid(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.wireguard.title.AddressInvalid (%@)", String(describing: p1), fallback: "Address ‘%@’ is invalid.")
        }
        /// Allowed IP ‘%@’ is invalid
        public static func allowedIPInvalid(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.wireguard.title.AllowedIPInvalid (%@)", String(describing: p1), fallback: "Allowed IP ‘%@’ is invalid")
        }
        /// DNS ‘%@’ is invalid.
        public static func dnsInvalid(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.wireguard.title.DNSInvalid (%@)", String(describing: p1), fallback: "DNS ‘%@’ is invalid.")
        }
        /// Endpoint ‘%@’ is invalid
        public static func endpointInvalid(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.wireguard.title.EndpointInvalid (%@)", String(describing: p1), fallback: "Endpoint ‘%@’ is invalid")
        }
        /// Valid keys are: ‘PrivateKey’, ‘ListenPort’, ‘Address’, ‘DNS’ and ‘MTU’.
        public static let infoUnrecognizedInterfaceKey = Strings.tr("Localizable", "errors.wireguard.title.InfoUnrecognizedInterfaceKey", fallback: "Valid keys are: ‘PrivateKey’, ‘ListenPort’, ‘Address’, ‘DNS’ and ‘MTU’.")
        /// Valid keys are: ‘PublicKey’, ‘PresharedKey’, ‘AllowedIPs’, ‘Endpoint’ and ‘PersistentKeepalive’
        public static let infoUnrecognizedPeerKey = Strings.tr("Localizable", "errors.wireguard.title.InfoUnrecognizedPeerKey", fallback: "Valid keys are: ‘PublicKey’, ‘PresharedKey’, ‘AllowedIPs’, ‘Endpoint’ and ‘PersistentKeepalive’")
        /// Invalid line: ‘%@’.
        public static func invalidLine(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.wireguard.title.InvalidLine (%@)", String(describing: p1), fallback: "Invalid line: ‘%@’.")
        }
        /// Listen port ‘%@’ is invalid.
        public static func listenPortInvalid(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.wireguard.title.ListenPortInvalid (%@)", String(describing: p1), fallback: "Listen port ‘%@’ is invalid.")
        }
        /// MTU ‘%@’ is invalid.
        public static func mtuInvalid(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.wireguard.title.MTUInvalid (%@)", String(describing: p1), fallback: "MTU ‘%@’ is invalid.")
        }
        /// There should be only one entry per section for key ‘%@’
        public static func multipleEntriesForKey(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.wireguard.title.MultipleEntriesForKey (%@)", String(describing: p1), fallback: "There should be only one entry per section for key ‘%@’")
        }
        /// Configuration must have only one ‘Interface’ section.
        public static let multipleInterfaces = Strings.tr("Localizable", "errors.wireguard.title.MultipleInterfaces", fallback: "Configuration must have only one ‘Interface’ section.")
        /// Configuration must have an ‘Interface’ section.
        public static let noInterface = Strings.tr("Localizable", "errors.wireguard.title.NoInterface", fallback: "Configuration must have an ‘Interface’ section.")
        /// Persistent keepalive value ‘%@’ is invalid
        public static func persistentKeepliveInvalid(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.wireguard.title.PersistentKeepliveInvalid (%@)", String(describing: p1), fallback: "Persistent keepalive value ‘%@’ is invalid")
        }
        /// Preshared key is invalid
        public static let preSharedKeyInvalid = Strings.tr("Localizable", "errors.wireguard.title.PreSharedKeyInvalid", fallback: "Preshared key is invalid")
        /// Private key is invalid.
        public static let privateKeyInvalid = Strings.tr("Localizable", "errors.wireguard.title.PrivateKeyInvalid", fallback: "Private key is invalid.")
        /// Public key is invalid
        public static let publicKeyInvalid = Strings.tr("Localizable", "errors.wireguard.title.PublicKeyInvalid", fallback: "Public key is invalid")
        /// Interface contains unrecognized key ‘%@’
        public static func unrecognizedInterfaceKey(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.wireguard.title.UnrecognizedInterfaceKey (%@)", String(describing: p1), fallback: "Interface contains unrecognized key ‘%@’")
        }
        /// Peer contains unrecognized key ‘%@’
        public static func unrecognizedPeerKey(_ p1: Any) -> String {
          return Strings.tr("Localizable", "errors.wireguard.title.UnrecognizedPeerKey (%@)", String(describing: p1), fallback: "Peer contains unrecognized key ‘%@’")
        }
      }
    }
  }
  public enum Features {
    /// %@
    public static func appletv(_ p1: Any) -> String {
      return Strings.tr("Localizable", "features.appletv", String(describing: p1), fallback: "%@")
    }
    /// DNS Settings
    public static let dns = Strings.tr("Localizable", "features.dns", fallback: "DNS Settings")
    /// HTTP Proxy Settings
    public static let httpProxy = Strings.tr("Localizable", "features.http_proxy", fallback: "HTTP Proxy Settings")
    /// Interactive Login
    public static let interactiveLogin = Strings.tr("Localizable", "features.interactiveLogin", fallback: "Interactive Login")
    /// On-Demand Rules
    public static let onDemand = Strings.tr("Localizable", "features.on_demand", fallback: "On-Demand Rules")
    /// All Providers
    public static let providers = Strings.tr("Localizable", "features.providers", fallback: "All Providers")
    /// Custom Routing
    public static let routing = Strings.tr("Localizable", "features.routing", fallback: "Custom Routing")
    /// %@ and Sharing
    public static func sharing(_ p1: Any) -> String {
      return Strings.tr("Localizable", "features.sharing", String(describing: p1), fallback: "%@ and Sharing")
    }
  }
  public enum Global {
    public enum Actions {
      /// Add
      public static let add = Strings.tr("Localizable", "global.actions.add", fallback: "Add")
      /// Allow
      public static let allow = Strings.tr("Localizable", "global.actions.allow", fallback: "Allow")
      /// Cancel
      public static let cancel = Strings.tr("Localizable", "global.actions.cancel", fallback: "Cancel")
      /// Connect
      public static let connect = Strings.tr("Localizable", "global.actions.connect", fallback: "Connect")
      /// Delete
      public static let delete = Strings.tr("Localizable", "global.actions.delete", fallback: "Delete")
      /// Disable
      public static let disable = Strings.tr("Localizable", "global.actions.disable", fallback: "Disable")
      /// Disconnect
      public static let disconnect = Strings.tr("Localizable", "global.actions.disconnect", fallback: "Disconnect")
      /// Duplicate
      public static let duplicate = Strings.tr("Localizable", "global.actions.duplicate", fallback: "Duplicate")
      /// Edit
      public static let edit = Strings.tr("Localizable", "global.actions.edit", fallback: "Edit")
      /// Enable
      public static let enable = Strings.tr("Localizable", "global.actions.enable", fallback: "Enable")
      /// Export
      public static let export = Strings.tr("Localizable", "global.actions.export", fallback: "Export")
      /// Hide
      public static let hide = Strings.tr("Localizable", "global.actions.hide", fallback: "Hide")
      /// Import
      public static let `import` = Strings.tr("Localizable", "global.actions.import", fallback: "Import")
      /// Purchase
      public static let purchase = Strings.tr("Localizable", "global.actions.purchase", fallback: "Purchase")
      /// Reconnect
      public static let reconnect = Strings.tr("Localizable", "global.actions.reconnect", fallback: "Reconnect")
      /// Delete
      public static let remove = Strings.tr("Localizable", "global.actions.remove", fallback: "Delete")
      /// Save
      public static let save = Strings.tr("Localizable", "global.actions.save", fallback: "Save")
      /// Select
      public static let select = Strings.tr("Localizable", "global.actions.select", fallback: "Select")
      /// Send
      public static let send = Strings.tr("Localizable", "global.actions.send", fallback: "Send")
      /// Show
      public static let show = Strings.tr("Localizable", "global.actions.show", fallback: "Show")
      /// Update
      public static let update = Strings.tr("Localizable", "global.actions.update", fallback: "Update")
    }
    public enum Nouns {
      /// About
      public static let about = Strings.tr("Localizable", "global.nouns.about", fallback: "About")
      /// Account
      public static let account = Strings.tr("Localizable", "global.nouns.account", fallback: "Account")
      /// Address
      public static let address = Strings.tr("Localizable", "global.nouns.address", fallback: "Address")
      /// Addresses
      public static let addresses = Strings.tr("Localizable", "global.nouns.addresses", fallback: "Addresses")
      /// Advanced
      public static let advanced = Strings.tr("Localizable", "global.nouns.advanced", fallback: "Advanced")
      /// Any
      public static let any = Strings.tr("Localizable", "global.nouns.any", fallback: "Any")
      /// Category
      public static let category = Strings.tr("Localizable", "global.nouns.category", fallback: "Category")
      /// Certificate
      public static let certificate = Strings.tr("Localizable", "global.nouns.certificate", fallback: "Certificate")
      /// Comment
      public static let comment = Strings.tr("Localizable", "global.nouns.comment", fallback: "Comment")
      /// Compression
      public static let compression = Strings.tr("Localizable", "global.nouns.compression", fallback: "Compression")
      /// Configuration
      public static let configuration = Strings.tr("Localizable", "global.nouns.configuration", fallback: "Configuration")
      /// Connection
      public static let connection = Strings.tr("Localizable", "global.nouns.connection", fallback: "Connection")
      /// Country
      public static let country = Strings.tr("Localizable", "global.nouns.country", fallback: "Country")
      /// Date
      public static let date = Strings.tr("Localizable", "global.nouns.date", fallback: "Date")
      /// Default
      public static let `default` = Strings.tr("Localizable", "global.nouns.default", fallback: "Default")
      /// Destination
      public static let destination = Strings.tr("Localizable", "global.nouns.destination", fallback: "Destination")
      /// Disabled
      public static let disabled = Strings.tr("Localizable", "global.nouns.disabled", fallback: "Disabled")
      /// Don't ask again
      public static let doNotAskAgain = Strings.tr("Localizable", "global.nouns.do_not_ask_again", fallback: "Don't ask again")
      /// Domain
      public static let domain = Strings.tr("Localizable", "global.nouns.domain", fallback: "Domain")
      /// Done
      public static let done = Strings.tr("Localizable", "global.nouns.done", fallback: "Done")
      /// Empty
      public static let empty = Strings.tr("Localizable", "global.nouns.empty", fallback: "Empty")
      /// Enabled
      public static let enabled = Strings.tr("Localizable", "global.nouns.enabled", fallback: "Enabled")
      /// Endpoint
      public static let endpoint = Strings.tr("Localizable", "global.nouns.endpoint", fallback: "Endpoint")
      /// %d Entries
      public static func entriesN(_ p1: Int) -> String {
        return Strings.tr("Localizable", "global.nouns.entries_n", p1, fallback: "%d Entries")
      }
      /// 1 Entry
      public static let entriesOne = Strings.tr("Localizable", "global.nouns.entries_one", fallback: "1 Entry")
      /// Features
      public static let features = Strings.tr("Localizable", "global.nouns.features", fallback: "Features")
      /// Filters
      public static let filters = Strings.tr("Localizable", "global.nouns.filters", fallback: "Filters")
      /// Folder
      public static let folder = Strings.tr("Localizable", "global.nouns.folder", fallback: "Folder")
      /// Gateway
      public static let gateway = Strings.tr("Localizable", "global.nouns.gateway", fallback: "Gateway")
      /// General
      public static let general = Strings.tr("Localizable", "global.nouns.general", fallback: "General")
      /// Hostname
      public static let hostname = Strings.tr("Localizable", "global.nouns.hostname", fallback: "Hostname")
      /// Interface
      public static let interface = Strings.tr("Localizable", "global.nouns.interface", fallback: "Interface")
      /// Interval
      public static let interval = Strings.tr("Localizable", "global.nouns.interval", fallback: "Interval")
      /// Keep-alive
      public static let keepAlive = Strings.tr("Localizable", "global.nouns.keep_alive", fallback: "Keep-alive")
      /// Key
      public static let key = Strings.tr("Localizable", "global.nouns.key", fallback: "Key")
      /// Last update
      public static let lastUpdate = Strings.tr("Localizable", "global.nouns.last_update", fallback: "Last update")
      /// Loading
      public static let loading = Strings.tr("Localizable", "global.nouns.loading", fallback: "Loading")
      /// Method
      public static let method = Strings.tr("Localizable", "global.nouns.method", fallback: "Method")
      /// Migration
      public static let migration = Strings.tr("Localizable", "global.nouns.migration", fallback: "Migration")
      /// Modules
      public static let modules = Strings.tr("Localizable", "global.nouns.modules", fallback: "Modules")
      /// %d seconds
      public static func nSeconds(_ p1: Int) -> String {
        return Strings.tr("Localizable", "global.nouns.n_seconds", p1, fallback: "%d seconds")
      }
      /// Name
      public static let name = Strings.tr("Localizable", "global.nouns.name", fallback: "Name")
      /// Networks
      public static let networks = Strings.tr("Localizable", "global.nouns.networks", fallback: "Networks")
      /// No
      public static let no = Strings.tr("Localizable", "global.nouns.no", fallback: "No")
      /// No content
      public static let noContent = Strings.tr("Localizable", "global.nouns.no_content", fallback: "No content")
      /// No selection
      public static let noSelection = Strings.tr("Localizable", "global.nouns.no_selection", fallback: "No selection")
      /// None
      public static let `none` = Strings.tr("Localizable", "global.nouns.none", fallback: "None")
      /// OK
      public static let ok = Strings.tr("Localizable", "global.nouns.ok", fallback: "OK")
      /// On-demand
      public static let onDemand = Strings.tr("Localizable", "global.nouns.on_demand", fallback: "On-demand")
      /// Other
      public static let other = Strings.tr("Localizable", "global.nouns.other", fallback: "Other")
      /// Passcode
      public static let passcode = Strings.tr("Localizable", "global.nouns.passcode", fallback: "Passcode")
      /// Password
      public static let password = Strings.tr("Localizable", "global.nouns.password", fallback: "Password")
      /// Port
      public static let port = Strings.tr("Localizable", "global.nouns.port", fallback: "Port")
      /// Preferences
      public static let preferences = Strings.tr("Localizable", "global.nouns.preferences", fallback: "Preferences")
      /// Private key
      public static let privateKey = Strings.tr("Localizable", "global.nouns.private_key", fallback: "Private key")
      /// Products
      public static let products = Strings.tr("Localizable", "global.nouns.products", fallback: "Products")
      /// Profile
      public static let profile = Strings.tr("Localizable", "global.nouns.profile", fallback: "Profile")
      /// Profiles
      public static let profiles = Strings.tr("Localizable", "global.nouns.profiles", fallback: "Profiles")
      /// Protocol
      public static let `protocol` = Strings.tr("Localizable", "global.nouns.protocol", fallback: "Protocol")
      /// Provider
      public static let provider = Strings.tr("Localizable", "global.nouns.provider", fallback: "Provider")
      /// Public key
      public static let publicKey = Strings.tr("Localizable", "global.nouns.public_key", fallback: "Public key")
      /// Purchases
      public static let purchases = Strings.tr("Localizable", "global.nouns.purchases", fallback: "Purchases")
      /// Region
      public static let region = Strings.tr("Localizable", "global.nouns.region", fallback: "Region")
      /// Route
      public static let route = Strings.tr("Localizable", "global.nouns.route", fallback: "Route")
      /// Routes
      public static let routes = Strings.tr("Localizable", "global.nouns.routes", fallback: "Routes")
      /// Routing
      public static let routing = Strings.tr("Localizable", "global.nouns.routing", fallback: "Routing")
      /// Server
      public static let server = Strings.tr("Localizable", "global.nouns.server", fallback: "Server")
      /// Servers
      public static let servers = Strings.tr("Localizable", "global.nouns.servers", fallback: "Servers")
      /// Settings
      public static let settings = Strings.tr("Localizable", "global.nouns.settings", fallback: "Settings")
      /// Status
      public static let status = Strings.tr("Localizable", "global.nouns.status", fallback: "Status")
      /// Subnet
      public static let subnet = Strings.tr("Localizable", "global.nouns.subnet", fallback: "Subnet")
      /// Timeout
      public static let timeout = Strings.tr("Localizable", "global.nouns.timeout", fallback: "Timeout")
      /// Troubleshooting
      public static let troubleshooting = Strings.tr("Localizable", "global.nouns.troubleshooting", fallback: "Troubleshooting")
      /// Unknown
      public static let unknown = Strings.tr("Localizable", "global.nouns.unknown", fallback: "Unknown")
      /// Username
      public static let username = Strings.tr("Localizable", "global.nouns.username", fallback: "Username")
      /// Version
      public static let version = Strings.tr("Localizable", "global.nouns.version", fallback: "Version")
      /// Yes
      public static let yes = Strings.tr("Localizable", "global.nouns.yes", fallback: "Yes")
      public enum Apple {
        /// Network Extensions
        public static let networkExtensions = Strings.tr("Localizable", "global.nouns.apple.network_extensions", fallback: "Network Extensions")
        /// System Extension
        public static let systemExtension = Strings.tr("Localizable", "global.nouns.apple.system_extension", fallback: "System Extension")
      }
    }
  }
  public enum Modules {
    public enum Dns {
      /// Route through VPN
      public static let routeThroughVpn = Strings.tr("Localizable", "modules.dns.route_through_vpn", fallback: "Route through VPN")
      public enum RouteThroughVpn {
        /// If enabled, DNS queries will be routed through the VPN tunnel.
        public static let footer = Strings.tr("Localizable", "modules.dns.route_through_vpn.footer", fallback: "If enabled, DNS queries will be routed through the VPN tunnel.")
      }
      public enum SearchDomains {
        /// Add domain
        public static let add = Strings.tr("Localizable", "modules.dns.search_domains.add", fallback: "Add domain")
      }
      public enum Servers {
        /// Add address
        public static let add = Strings.tr("Localizable", "modules.dns.servers.add", fallback: "Add address")
      }
    }
    public enum General {
      public enum Rows {
        /// %@
        public static func appletv(_ p1: Any) -> String {
          return Strings.tr("Localizable", "modules.general.rows.appletv", String(describing: p1), fallback: "%@")
        }
        /// Enforce tunnel
        public static let enforceTunnel = Strings.tr("Localizable", "modules.general.rows.enforce_tunnel", fallback: "Enforce tunnel")
        /// Import from file
        public static let importFromFile = Strings.tr("Localizable", "modules.general.rows.import_from_file", fallback: "Import from file")
        /// Keep alive on sleep
        public static let keepAliveOnSleep = Strings.tr("Localizable", "modules.general.rows.keep_alive_on_sleep", fallback: "Keep alive on sleep")
        /// Enabled
        public static let shared = Strings.tr("Localizable", "modules.general.rows.shared", fallback: "Enabled")
        public enum Appletv {
          /// Drop TV restriction
          public static let purchase = Strings.tr("Localizable", "modules.general.rows.appletv.purchase", fallback: "Drop TV restriction")
        }
        public enum EnforceTunnel {
          /// Try to send most network traffic over the tunnel. Beware that this may degrade your connectivity.
          public static let footer = Strings.tr("Localizable", "modules.general.rows.enforce_tunnel.footer", fallback: "Try to send most network traffic over the tunnel. Beware that this may degrade your connectivity.")
        }
        public enum KeepAliveOnSleep {
          /// Disable to improve battery usage, at the expense of occasional slowdowns due to wake-up reconnections.
          public static let footer = Strings.tr("Localizable", "modules.general.rows.keep_alive_on_sleep.footer", fallback: "Disable to improve battery usage, at the expense of occasional slowdowns due to wake-up reconnections.")
        }
        public enum Shared {
          /// Share on iCloud
          public static let purchase = Strings.tr("Localizable", "modules.general.rows.shared.purchase", fallback: "Share on iCloud")
        }
      }
      public enum Sections {
        public enum Behavior {
          /// Behavior
          public static let header = Strings.tr("Localizable", "modules.general.sections.behavior.header", fallback: "Behavior")
        }
        public enum Storage {
          /// Synchronization
          public static let header = Strings.tr("Localizable", "modules.general.sections.storage.header", fallback: "Synchronization")
          public enum Sharing {
            /// Profiles are stored to %@ encrypted.
            public static func footer(_ p1: Any) -> String {
              return Strings.tr("Localizable", "modules.general.sections.storage.sharing.footer", String(describing: p1), fallback: "Profiles are stored to %@ encrypted.")
            }
          }
          public enum Tv {
            public enum Footer {
              /// The TV may require an additional purchase.
              public static let purchaseUnsupported = Strings.tr("Localizable", "modules.general.sections.storage.tv.footer.purchase_unsupported", fallback: "The TV may require an additional purchase.")
            }
            public enum Icloud {
              /// iCloud is required to synchronize your profiles with your TV.
              public static let footer = Strings.tr("Localizable", "modules.general.sections.storage.tv.icloud.footer", fallback: "iCloud is required to synchronize your profiles with your TV.")
            }
            public enum Web {
              /// You can send the profile to your TV over the web.
              public static let footer = Strings.tr("Localizable", "modules.general.sections.storage.tv.web.footer", fallback: "You can send the profile to your TV over the web.")
            }
          }
        }
      }
    }
    public enum HttpProxy {
      public enum BypassDomains {
        /// Add bypass domain
        public static let add = Strings.tr("Localizable", "modules.http_proxy.bypass_domains.add", fallback: "Add bypass domain")
      }
    }
    public enum Ip {
      public enum Address {
        /// Leave empty to assign automatically.
        public static let footer = Strings.tr("Localizable", "modules.ip.address.footer", fallback: "Leave empty to assign automatically.")
      }
      public enum Routes {
        /// Add %@
        public static func addFamily(_ p1: Any) -> String {
          return Strings.tr("Localizable", "modules.ip.routes.add_family", String(describing: p1), fallback: "Add %@")
        }
        /// Exclude route
        public static let exclude = Strings.tr("Localizable", "modules.ip.routes.exclude", fallback: "Exclude route")
        /// Excluded routes
        public static let excluded = Strings.tr("Localizable", "modules.ip.routes.excluded", fallback: "Excluded routes")
        /// Include route
        public static let include = Strings.tr("Localizable", "modules.ip.routes.include", fallback: "Include route")
        /// Included routes
        public static let included = Strings.tr("Localizable", "modules.ip.routes.included", fallback: "Included routes")
      }
    }
    public enum OnDemand {
      /// Ethernet
      public static let ethernet = Strings.tr("Localizable", "modules.on_demand.ethernet", fallback: "Ethernet")
      /// Mobile
      public static let mobile = Strings.tr("Localizable", "modules.on_demand.mobile", fallback: "Mobile")
      /// Policy
      public static let policy = Strings.tr("Localizable", "modules.on_demand.policy", fallback: "Policy")
      public enum Networks {
        /// These rules will only apply on devices where the interface type is supported.
        public static let footer = Strings.tr("Localizable", "modules.on_demand.networks.footer", fallback: "These rules will only apply on devices where the interface type is supported.")
      }
      public enum Policy {
        /// Activate the VPN %@.
        public static func footer(_ p1: Any) -> String {
          return Strings.tr("Localizable", "modules.on_demand.policy.footer", String(describing: p1), fallback: "Activate the VPN %@.")
        }
        public enum Footer {
          /// in any network
          public static let any = Strings.tr("Localizable", "modules.on_demand.policy.footer.any", fallback: "in any network")
          /// except in the networks below
          public static let excluding = Strings.tr("Localizable", "modules.on_demand.policy.footer.excluding", fallback: "except in the networks below")
          /// only in the networks below
          public static let including = Strings.tr("Localizable", "modules.on_demand.policy.footer.including", fallback: "only in the networks below")
        }
      }
      public enum Ssid {
        /// Add SSID
        public static let add = Strings.tr("Localizable", "modules.on_demand.ssid.add", fallback: "Add SSID")
      }
    }
    public enum Openvpn {
      /// Cipher
      public static let cipher = Strings.tr("Localizable", "modules.openvpn.cipher", fallback: "Cipher")
      /// Communication
      public static let communication = Strings.tr("Localizable", "modules.openvpn.communication", fallback: "Communication")
      /// Compression
      public static let compression = Strings.tr("Localizable", "modules.openvpn.compression", fallback: "Compression")
      /// Algorithm
      public static let compressionAlgorithm = Strings.tr("Localizable", "modules.openvpn.compression_algorithm", fallback: "Algorithm")
      /// Framing
      public static let compressionFraming = Strings.tr("Localizable", "modules.openvpn.compression_framing", fallback: "Framing")
      /// Credentials
      public static let credentials = Strings.tr("Localizable", "modules.openvpn.credentials", fallback: "Credentials")
      /// Digest
      public static let digest = Strings.tr("Localizable", "modules.openvpn.digest", fallback: "Digest")
      /// Extended verification
      public static let eku = Strings.tr("Localizable", "modules.openvpn.eku", fallback: "Extended verification")
      /// Pull
      public static let pull = Strings.tr("Localizable", "modules.openvpn.pull", fallback: "Pull")
      /// Randomize endpoint
      public static let randomizeEndpoint = Strings.tr("Localizable", "modules.openvpn.randomize_endpoint", fallback: "Randomize endpoint")
      /// Randomize hostname
      public static let randomizeHostname = Strings.tr("Localizable", "modules.openvpn.randomize_hostname", fallback: "Randomize hostname")
      /// Redirect gateway
      public static let redirectGateway = Strings.tr("Localizable", "modules.openvpn.redirect_gateway", fallback: "Redirect gateway")
      /// Remote endpoints
      public static let remotes = Strings.tr("Localizable", "modules.openvpn.remotes", fallback: "Remote endpoints")
      /// Renegotiation
      public static let renegotiation = Strings.tr("Localizable", "modules.openvpn.renegotiation", fallback: "Renegotiation")
      /// Wrapping
      public static let tlsWrap = Strings.tr("Localizable", "modules.openvpn.tls_wrap", fallback: "Wrapping")
      public enum Credentials {
        /// Interactive
        public static let interactive = Strings.tr("Localizable", "modules.openvpn.credentials.interactive", fallback: "Interactive")
        public enum Guidance {
          /// See your OpenVPN credentials
          public static let link = Strings.tr("Localizable", "modules.openvpn.credentials.guidance.link", fallback: "See your OpenVPN credentials")
          /// Use your specific OpenVPN credentials, which are not the same credentials you log in with.
          public static let specific = Strings.tr("Localizable", "modules.openvpn.credentials.guidance.specific", fallback: "Use your specific OpenVPN credentials, which are not the same credentials you log in with.")
          /// Use your login credentials.
          public static let web = Strings.tr("Localizable", "modules.openvpn.credentials.guidance.web", fallback: "Use your login credentials.")
        }
        public enum Interactive {
          /// On-demand will be disabled.
          public static let footer = Strings.tr("Localizable", "modules.openvpn.credentials.interactive.footer", fallback: "On-demand will be disabled.")
        }
        public enum OtpMethod {
          public enum Approach {
            /// The OTP will be appended to the password.
            public static let append = Strings.tr("Localizable", "modules.openvpn.credentials.otp_method.approach.append", fallback: "The OTP will be appended to the password.")
            /// The OTP will be encoded in Base64 with the password.
            public static let encode = Strings.tr("Localizable", "modules.openvpn.credentials.otp_method.approach.encode", fallback: "The OTP will be encoded in Base64 with the password.")
          }
        }
      }
    }
    public enum Wireguard {
      /// Allowed IPs
      public static let allowedIps = Strings.tr("Localizable", "modules.wireguard.allowed_ips", fallback: "Allowed IPs")
      /// Interface
      public static let interface = Strings.tr("Localizable", "modules.wireguard.interface", fallback: "Interface")
      /// Peer #%d
      public static func peer(_ p1: Int) -> String {
        return Strings.tr("Localizable", "modules.wireguard.peer", p1, fallback: "Peer #%d")
      }
      /// Pre-shared key
      public static let presharedKey = Strings.tr("Localizable", "modules.wireguard.preshared_key", fallback: "Pre-shared key")
      public enum Peer {
        /// Add peer
        public static let add = Strings.tr("Localizable", "modules.wireguard.peer.add", fallback: "Add peer")
        /// Delete peer
        public static let delete = Strings.tr("Localizable", "modules.wireguard.peer.delete", fallback: "Delete peer")
      }
      public enum PrivateKey {
        /// Generate new key
        public static let generate = Strings.tr("Localizable", "modules.wireguard.private_key.generate", fallback: "Generate new key")
      }
    }
  }
  public enum Onboarding {
    public enum Community {
      /// No, thanks
      public static let dismiss = Strings.tr("Localizable", "onboarding.community.dismiss", fallback: "No, thanks")
      /// Did you know that %@ has a subreddit? Subscribe for updates or to discuss issues, features, new platforms or whatever you like.
      /// 
      /// It's also a great way to show you care about this project.
      public static func message(_ p1: Any) -> String {
        return Strings.tr("Localizable", "onboarding.community.message", String(describing: p1), fallback: "Did you know that %@ has a subreddit? Subscribe for updates or to discuss issues, features, new platforms or whatever you like.\n\nIt's also a great way to show you care about this project.")
      }
      /// Subscribe now
      public static let subscribe = Strings.tr("Localizable", "onboarding.community.subscribe", fallback: "Subscribe now")
    }
    public enum DropLzo {
      /// Due to security concerns (specifically the VORACLE vulnerability), OpenVPN deprecated compression support years ago. Starting in December 2025, Passepartout will also remove support for LZO compression. If your OpenVPN connection stops working, please make sure that compression is disabled on your server. Most public VPN providers have already done this, so you are unlikely to be affected.
      public static let message = Strings.tr("Localizable", "onboarding.drop_lzo.message", fallback: "Due to security concerns (specifically the VORACLE vulnerability), OpenVPN deprecated compression support years ago. Starting in December 2025, Passepartout will also remove support for LZO compression. If your OpenVPN connection stops working, please make sure that compression is disabled on your server. Most public VPN providers have already done this, so you are unlikely to be affected.")
    }
    public enum Migrate {
      /// Make sure to upgrade all your devices to the latest version to use the new profiles.
      public static let message = Strings.tr("Localizable", "onboarding.migrate.message", fallback: "Make sure to upgrade all your devices to the latest version to use the new profiles.")
    }
    public enum Migrate323 {
      /// Version 3.2.3 changed the way providers are stored.
      public static let message = Strings.tr("Localizable", "onboarding.migrate_3_2_3.message", fallback: "Version 3.2.3 changed the way providers are stored.")
    }
    public enum Migrate3515 {
      /// Version 3.5.15 changed the way profiles are stored.
      public static let message = Strings.tr("Localizable", "onboarding.migrate_3_5_15.message", fallback: "Version 3.5.15 changed the way profiles are stored.")
    }
  }
  public enum Placeholders {
    /// secret
    public static let secret = Strings.tr("Localizable", "placeholders.secret", fallback: "secret")
    /// username
    public static let username = Strings.tr("Localizable", "placeholders.username", fallback: "username")
    public enum OnDemand {
      /// My SSID
      public static let ssid = Strings.tr("Localizable", "placeholders.on_demand.ssid", fallback: "My SSID")
    }
    public enum Profile {
      /// Imported profile
      public static let importedName = Strings.tr("Localizable", "placeholders.profile.imported_name", fallback: "Imported profile")
      /// My profile
      public static let name = Strings.tr("Localizable", "placeholders.profile.name", fallback: "My profile")
    }
  }
  public enum Theme {
    public enum Confirmation {
      /// Cancel
      public static let cancel = Strings.tr("Localizable", "theme.confirmation.cancel", fallback: "Cancel")
      /// Are you sure you want to proceed with this operation?
      public static let message = Strings.tr("Localizable", "theme.confirmation.message", fallback: "Are you sure you want to proceed with this operation?")
      /// Confirm
      public static let ok = Strings.tr("Localizable", "theme.confirmation.ok", fallback: "Confirm")
    }
    public enum LockScreen {
      /// %@ is locked
      public static func reason(_ p1: Any) -> String {
        return Strings.tr("Localizable", "theme.lock_screen.reason", String(describing: p1), fallback: "%@ is locked")
      }
    }
  }
  public enum Tips {
    public enum Profile {
      public enum BuildYourProfile {
        /// Add and delete modules to customize your connection profile.
        public static let message = Strings.tr("Localizable", "tips.profile.build_your_profile.message", fallback: "Add and delete modules to customize your connection profile.")
        /// Build your profile here
        public static let title = Strings.tr("Localizable", "tips.profile.build_your_profile.title", fallback: "Build your profile here")
      }
    }
  }
  public enum Views {
    public enum App {
      public enum Folders {
        /// My profiles
        public static let `default` = Strings.tr("Localizable", "views.app.folders.default", fallback: "My profiles")
        /// No profiles
        public static let noProfiles = Strings.tr("Localizable", "views.app.folders.no_profiles", fallback: "No profiles")
        public enum NoProfiles {
          /// Migrate old profiles...
          public static let migrate = Strings.tr("Localizable", "views.app.folders.no_profiles.migrate", fallback: "Migrate old profiles...")
        }
      }
      public enum InstalledProfile {
        public enum None {
          /// No profile
          public static let name = Strings.tr("Localizable", "views.app.installed_profile.none.name", fallback: "No profile")
          /// Tap list to connect
          public static let status = Strings.tr("Localizable", "views.app.installed_profile.none.status", fallback: "Tap list to connect")
        }
      }
      public enum Profile {
        /// No active modules
        public static let noModules = Strings.tr("Localizable", "views.app.profile.no_modules", fallback: "No active modules")
      }
      public enum ProfileContext {
        /// Connect to
        public static let connectTo = Strings.tr("Localizable", "views.app.profile_context.connect_to", fallback: "Connect to")
      }
      public enum Toolbar {
        /// Import file
        public static let importFile = Strings.tr("Localizable", "views.app.toolbar.import_file", fallback: "Import file")
        /// Migrate profiles
        public static let migrateProfiles = Strings.tr("Localizable", "views.app.toolbar.migrate_profiles", fallback: "Migrate profiles")
        public enum ImportQr {
          /// Import QR
          public static let title = Strings.tr("Localizable", "views.app.toolbar.import_qr.title", fallback: "Import QR")
        }
        public enum ImportText {
          /// Paste your profile content below.
          public static let caption = Strings.tr("Localizable", "views.app.toolbar.import_text.caption", fallback: "Paste your profile content below.")
          /// Import text
          public static let title = Strings.tr("Localizable", "views.app.toolbar.import_text.title", fallback: "Import text")
        }
        public enum NewProfile {
          /// Empty profile
          public static let empty = Strings.tr("Localizable", "views.app.toolbar.new_profile.empty", fallback: "Empty profile")
          /// Provider
          public static let provider = Strings.tr("Localizable", "views.app.toolbar.new_profile.provider", fallback: "Provider")
        }
      }
    }
    public enum AppMenu {
      public enum Items {
        /// Quit %@
        public static func quit(_ p1: Any) -> String {
          return Strings.tr("Localizable", "views.app_menu.items.quit", String(describing: p1), fallback: "Quit %@")
        }
      }
    }
    public enum Diagnostics {
      /// Diagnostics
      public static let title = Strings.tr("Localizable", "views.diagnostics.title", fallback: "Diagnostics")
      public enum Alerts {
        public enum ReportIssue {
          /// The device is not configured to send e-mails.
          public static let email = Strings.tr("Localizable", "views.diagnostics.alerts.report_issue.email", fallback: "The device is not configured to send e-mails.")
        }
      }
      public enum Openvpn {
        public enum Rows {
          /// Server configuration
          public static let serverConfiguration = Strings.tr("Localizable", "views.diagnostics.openvpn.rows.server_configuration", fallback: "Server configuration")
        }
      }
      public enum ReportIssue {
        /// Report issue
        public static let title = Strings.tr("Localizable", "views.diagnostics.report_issue.title", fallback: "Report issue")
      }
      public enum Rows {
        /// App
        public static let app = Strings.tr("Localizable", "views.diagnostics.rows.app", fallback: "App")
        /// Include private data
        public static let includePrivateData = Strings.tr("Localizable", "views.diagnostics.rows.include_private_data", fallback: "Include private data")
        /// Delete all logs
        public static let removeTunnelLogs = Strings.tr("Localizable", "views.diagnostics.rows.remove_tunnel_logs", fallback: "Delete all logs")
        /// Tunnel
        public static let tunnel = Strings.tr("Localizable", "views.diagnostics.rows.tunnel", fallback: "Tunnel")
      }
      public enum Sections {
        /// Active profiles
        public static let activeProfiles = Strings.tr("Localizable", "views.diagnostics.sections.active_profiles", fallback: "Active profiles")
        /// Live log
        public static let live = Strings.tr("Localizable", "views.diagnostics.sections.live", fallback: "Live log")
        /// Tunnel logs
        public static let tunnel = Strings.tr("Localizable", "views.diagnostics.sections.tunnel", fallback: "Tunnel logs")
      }
    }
    public enum Donate {
      /// Make a donation
      public static let title = Strings.tr("Localizable", "views.donate.title", fallback: "Make a donation")
      public enum Alerts {
        public enum ThankYou {
          /// This means a lot to me and I really hope you keep using and promoting this app.
          public static let message = Strings.tr("Localizable", "views.donate.alerts.thank_you.message", fallback: "This means a lot to me and I really hope you keep using and promoting this app.")
        }
      }
      public enum Sections {
        public enum Main {
          /// If you want to display gratitude for my work, here are a couple of amounts you can donate instantly. You will only be charged once per donation, and you can donate multiple times.
          public static let footer = Strings.tr("Localizable", "views.donate.sections.main.footer", fallback: "If you want to display gratitude for my work, here are a couple of amounts you can donate instantly. You will only be charged once per donation, and you can donate multiple times.")
        }
      }
    }
    public enum Migration {
      /// Nothing to migrate
      public static let noProfiles = Strings.tr("Localizable", "views.migration.no_profiles", fallback: "Nothing to migrate")
      /// Migrate
      public static let title = Strings.tr("Localizable", "views.migration.title", fallback: "Migrate")
      public enum Alerts {
        public enum Delete {
          /// Do you want to discard these profiles? You will not be able to recover them later.
          /// 
          /// %@
          public static func message(_ p1: Any) -> String {
            return Strings.tr("Localizable", "views.migration.alerts.delete.message", String(describing: p1), fallback: "Do you want to discard these profiles? You will not be able to recover them later.\n\n%@")
          }
        }
      }
      public enum Items {
        /// Discard
        public static let discard = Strings.tr("Localizable", "views.migration.items.discard", fallback: "Discard")
        /// Proceed
        public static let migrate = Strings.tr("Localizable", "views.migration.items.migrate", fallback: "Proceed")
      }
      public enum Sections {
        public enum Main {
          /// Select below the profiles from old versions of %@ that you want to import. In case your profiles are stored on iCloud, they may take a while to synchronize. If you do not see them now, please come back later.
          public static func header(_ p1: Any) -> String {
            return Strings.tr("Localizable", "views.migration.sections.main.header", String(describing: p1), fallback: "Select below the profiles from old versions of %@ that you want to import. In case your profiles are stored on iCloud, they may take a while to synchronize. If you do not see them now, please come back later.")
          }
        }
      }
    }
    public enum Paywall {
      public enum Alerts {
        public enum Confirmation {
          /// Edit profile
          public static let editProfile = Strings.tr("Localizable", "views.paywall.alerts.confirmation.edit_profile", fallback: "Edit profile")
          /// This profile requires paid features to work.
          public static let message = Strings.tr("Localizable", "views.paywall.alerts.confirmation.message", fallback: "This profile requires paid features to work.")
          /// Purchase required
          public static let title = Strings.tr("Localizable", "views.paywall.alerts.confirmation.title", fallback: "Purchase required")
          public enum Message {
            /// You may test the connection for %d minutes.
            public static func connect(_ p1: Int) -> String {
              return Strings.tr("Localizable", "views.paywall.alerts.confirmation.message.connect", p1, fallback: "You may test the connection for %d minutes.")
            }
            /// Tap the lock icons to purchase the missing features.
            public static let save = Strings.tr("Localizable", "views.paywall.alerts.confirmation.message.save", fallback: "Tap the lock icons to purchase the missing features.")
          }
        }
        public enum Pending {
          /// The purchase is pending external confirmation. The feature will be credited upon approval.
          public static let message = Strings.tr("Localizable", "views.paywall.alerts.pending.message", fallback: "The purchase is pending external confirmation. The feature will be credited upon approval.")
        }
        public enum Verification {
          /// This may take a little longer if your device was just started.
          public static let boot = Strings.tr("Localizable", "views.paywall.alerts.verification.boot", fallback: "This may take a little longer if your device was just started.")
          /// Please wait while your purchases are being verified.
          public static let edit = Strings.tr("Localizable", "views.paywall.alerts.verification.edit", fallback: "Please wait while your purchases are being verified.")
          public enum Connect {
            /// Your purchases are being verified.
            public static let _1 = Strings.tr("Localizable", "views.paywall.alerts.verification.connect.1", fallback: "Your purchases are being verified.")
            /// If verification cannot be completed, the connection will end in %d minutes.
            public static func _2(_ p1: Int) -> String {
              return Strings.tr("Localizable", "views.paywall.alerts.verification.connect.2", p1, fallback: "If verification cannot be completed, the connection will end in %d minutes.")
            }
          }
        }
      }
      public enum Product {
        /// Included features
        public static let includedFeatures = Strings.tr("Localizable", "views.paywall.product.included_features", fallback: "Included features")
      }
      public enum Rows {
        /// Restore purchases
        public static let restorePurchases = Strings.tr("Localizable", "views.paywall.rows.restore_purchases", fallback: "Restore purchases")
      }
      public enum Sections {
        public enum FullProducts {
          /// These products include current and future features.
          public static let footer = Strings.tr("Localizable", "views.paywall.sections.full_products.footer", fallback: "These products include current and future features.")
          /// All features
          public static let header = Strings.tr("Localizable", "views.paywall.sections.full_products.header", fallback: "All features")
        }
        public enum Products {
          /// All purchases support Family Sharing.
          public static let footer = Strings.tr("Localizable", "views.paywall.sections.products.footer", fallback: "All purchases support Family Sharing.")
          /// Suggested products
          public static let header = Strings.tr("Localizable", "views.paywall.sections.products.header", fallback: "Suggested products")
        }
        public enum RequiredFeatures {
          /// Required features
          public static let header = Strings.tr("Localizable", "views.paywall.sections.required_features.header", fallback: "Required features")
        }
        public enum Restore {
          /// If you made purchases in the past, you can restore them here.
          public static let footer = Strings.tr("Localizable", "views.paywall.sections.restore.footer", fallback: "If you made purchases in the past, you can restore them here.")
          /// Restore
          public static let header = Strings.tr("Localizable", "views.paywall.sections.restore.header", fallback: "Restore")
        }
      }
    }
    public enum PaywallNew {
      public enum Sections {
        public enum Products {
          /// Purchase individually
          public static let header = Strings.tr("Localizable", "views.paywall_new.sections.products.header", fallback: "Purchase individually")
        }
      }
    }
    public enum Preferences {
      /// DNS fallback
      public static let dnsFallsBack = Strings.tr("Localizable", "views.preferences.dns_falls_back", fallback: "DNS fallback")
      /// In-app purchases
      public static let enablesIap = Strings.tr("Localizable", "views.preferences.enables_iap", fallback: "In-app purchases")
      /// Erase profiles from iCloud
      public static let eraseIcloud = Strings.tr("Localizable", "views.preferences.erase_icloud", fallback: "Erase profiles from iCloud")
      /// Keep in menu bar
      public static let keepsInMenu = Strings.tr("Localizable", "views.preferences.keeps_in_menu", fallback: "Keep in menu bar")
      /// Launch on login
      public static let launchesOnLogin = Strings.tr("Localizable", "views.preferences.launches_on_login", fallback: "Launch on login")
      /// Lock in background
      public static let locksInBackground = Strings.tr("Localizable", "views.preferences.locks_in_background", fallback: "Lock in background")
      /// Modern cryptography
      public static let modernCrypto = Strings.tr("Localizable", "views.preferences.modern_crypto", fallback: "Modern cryptography")
      /// Pin active profile
      public static let pinsActiveProfile = Strings.tr("Localizable", "views.preferences.pins_active_profile", fallback: "Pin active profile")
      /// Alternative verification
      public static let relaxedVerification = Strings.tr("Localizable", "views.preferences.relaxed_verification", fallback: "Alternative verification")
      /// Appearance
      public static let systemAppearance = Strings.tr("Localizable", "views.preferences.system_appearance", fallback: "Appearance")
      public enum Advanced {
        public enum Remote {
          /// These features are controlled remotely. Turn off the toggles if something does not work.
          public static let footer = Strings.tr("Localizable", "views.preferences.advanced.remote.footer", fallback: "These features are controlled remotely. Turn off the toggles if something does not work.")
        }
      }
      public enum DnsFallsBack {
        /// Fall back to CloudFlare servers when the VPN does not provide DNS settings.
        public static let footer = Strings.tr("Localizable", "views.preferences.dns_falls_back.footer", fallback: "Fall back to CloudFlare servers when the VPN does not provide DNS settings.")
      }
      public enum EnablesIap {
        /// Enable support for paid features. Disable this if you do not have an Apple ID.
        public static let footer = Strings.tr("Localizable", "views.preferences.enables_iap.footer", fallback: "Enable support for paid features. Disable this if you do not have an Apple ID.")
      }
      public enum EraseIcloud {
        /// To erase all profiles from the iCloud store securely, do so on all your synced devices. This will not affect local profiles.
        public static let footer = Strings.tr("Localizable", "views.preferences.erase_icloud.footer", fallback: "To erase all profiles from the iCloud store securely, do so on all your synced devices. This will not affect local profiles.")
      }
      public enum KeepsInMenu {
        /// Enable this to keep the app in the menu bar after closing it.
        public static let footer = Strings.tr("Localizable", "views.preferences.keeps_in_menu.footer", fallback: "Enable this to keep the app in the menu bar after closing it.")
      }
      public enum LaunchesOnLogin {
        /// Open the app in background after login.
        public static let footer = Strings.tr("Localizable", "views.preferences.launches_on_login.footer", fallback: "Open the app in background after login.")
      }
      public enum LocksInBackground {
        /// Lock the app with FaceID when sent to the background.
        public static let footer = Strings.tr("Localizable", "views.preferences.locks_in_background.footer", fallback: "Lock the app with FaceID when sent to the background.")
      }
      public enum ModernCrypto {
        /// Use modern and faster implementations of cryptographic algorithms, though potentially unstable.
        public static let footer = Strings.tr("Localizable", "views.preferences.modern_crypto.footer", fallback: "Use modern and faster implementations of cryptographic algorithms, though potentially unstable.")
      }
      public enum PinsActiveProfile {
        /// Also show the active profile on top for quick access.
        public static let footer = Strings.tr("Localizable", "views.preferences.pins_active_profile.footer", fallback: "Also show the active profile on top for quick access.")
      }
    }
    public enum Profile {
      public enum Alerts {
        public enum Purchase {
          public enum Buttons {
            /// Save anyway
            public static let ok = Strings.tr("Localizable", "views.profile.alerts.purchase.buttons.ok", fallback: "Save anyway")
          }
        }
      }
      public enum Buttons {
        /// Export profile
        public static let export = Strings.tr("Localizable", "views.profile.buttons.export", fallback: "Export profile")
        /// Share profile
        public static let share = Strings.tr("Localizable", "views.profile.buttons.share", fallback: "Share profile")
      }
      public enum ModuleList {
        public enum Section {
          /// Tap modules to edit their settings. Modules may be dragged to determine priority.
          public static let footer = Strings.tr("Localizable", "views.profile.module_list.section.footer", fallback: "Tap modules to edit their settings. Modules may be dragged to determine priority.")
        }
      }
      public enum Rows {
        /// Add module
        public static let addModule = Strings.tr("Localizable", "views.profile.rows.add_module", fallback: "Add module")
        /// Delete profile
        public static let deleteProfile = Strings.tr("Localizable", "views.profile.rows.delete_profile", fallback: "Delete profile")
        /// Unlock sharing features
        public static let purchaseSharingFeatures = Strings.tr("Localizable", "views.profile.rows.purchase_sharing_features", fallback: "Unlock sharing features")
      }
      public enum Sections {
        public enum Name {
          /// Use this name to create your VPN automations from the Shortcuts app.
          public static let footer = Strings.tr("Localizable", "views.profile.sections.name.footer", fallback: "Use this name to create your VPN automations from the Shortcuts app.")
        }
      }
      public enum SendTv {
        /// Send to %@
        public static func title(_ p1: Any) -> String {
          return Strings.tr("Localizable", "views.profile.send_tv.title", String(describing: p1), fallback: "Send to %@")
        }
        public enum Form {
          /// Match the URL found in '%@ > %@' on your %@, making sure to be on the same network.
          public static func message(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
            return Strings.tr("Localizable", "views.profile.send_tv.form.message", String(describing: p1), String(describing: p2), String(describing: p3), fallback: "Match the URL found in '%@ > %@' on your %@, making sure to be on the same network.")
          }
        }
        public enum Passcode {
          /// Enter the passcode
          public static let message = Strings.tr("Localizable", "views.profile.send_tv.passcode.message", fallback: "Enter the passcode")
        }
        public enum Qr {
          /// Scan the QR found in '%@ > %@' on your %@, making sure to be on the same network
          public static func message(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
            return Strings.tr("Localizable", "views.profile.send_tv.qr.message", String(describing: p1), String(describing: p2), String(describing: p3), fallback: "Scan the QR found in '%@ > %@' on your %@, making sure to be on the same network")
          }
          public enum Buttons {
            /// Enter URL manually
            public static let manual = Strings.tr("Localizable", "views.profile.send_tv.qr.buttons.manual", fallback: "Enter URL manually")
          }
        }
      }
    }
    public enum Providers {
      /// Clear filters
      public static let clearFilters = Strings.tr("Localizable", "views.providers.clear_filters", fallback: "Clear filters")
      /// Last updated on %@
      public static func lastUpdated(_ p1: Any) -> String {
        return Strings.tr("Localizable", "views.providers.last_updated", String(describing: p1), fallback: "Last updated on %@")
      }
      /// Type
      public static let module = Strings.tr("Localizable", "views.providers.module", fallback: "Type")
      /// Only favorites
      public static let onlyFavorites = Strings.tr("Localizable", "views.providers.only_favorites", fallback: "Only favorites")
      /// Preset
      public static let preset = Strings.tr("Localizable", "views.providers.preset", fallback: "Preset")
      /// Refresh infrastructure
      public static let refreshInfrastructure = Strings.tr("Localizable", "views.providers.refresh_infrastructure", fallback: "Refresh infrastructure")
      /// Select
      public static let selectEntity = Strings.tr("Localizable", "views.providers.select_entity", fallback: "Select")
      /// Select type
      public static let selectModule = Strings.tr("Localizable", "views.providers.select_module", fallback: "Select type")
      /// Select provider
      public static let selectProvider = Strings.tr("Localizable", "views.providers.select_provider", fallback: "Select provider")
      public enum LastUpdated {
        /// Loading...
        public static let loading = Strings.tr("Localizable", "views.providers.last_updated.loading", fallback: "Loading...")
      }
      public enum Preset {
        /// Select server
        public static let placeholder = Strings.tr("Localizable", "views.providers.preset.placeholder", fallback: "Select server")
      }
    }
    public enum Purchased {
      /// No purchases
      public static let noPurchases = Strings.tr("Localizable", "views.purchased.no_purchases", fallback: "No purchases")
      /// Purchased
      public static let title = Strings.tr("Localizable", "views.purchased.title", fallback: "Purchased")
      public enum Rows {
        /// Build number
        public static let buildNumber = Strings.tr("Localizable", "views.purchased.rows.build_number", fallback: "Build number")
      }
      public enum Sections {
        public enum Download {
          /// First download
          public static let header = Strings.tr("Localizable", "views.purchased.sections.download.header", fallback: "First download")
        }
      }
    }
    public enum Settings {
      /// Settings
      public static let title = Strings.tr("Localizable", "views.settings.title", fallback: "Settings")
      public enum Credits {
        /// Licenses
        public static let licenses = Strings.tr("Localizable", "views.settings.credits.licenses", fallback: "Licenses")
        /// Notices
        public static let notices = Strings.tr("Localizable", "views.settings.credits.notices", fallback: "Notices")
        /// Credits
        public static let title = Strings.tr("Localizable", "views.settings.credits.title", fallback: "Credits")
        /// Translations
        public static let translations = Strings.tr("Localizable", "views.settings.credits.translations", fallback: "Translations")
      }
      public enum Links {
        /// Links
        public static let title = Strings.tr("Localizable", "views.settings.links.title", fallback: "Links")
        /// Update to %@
        public static func update(_ p1: Any) -> String {
          return Strings.tr("Localizable", "views.settings.links.update", String(describing: p1), fallback: "Update to %@")
        }
        public enum Rows {
          /// Blog
          public static let blog = Strings.tr("Localizable", "views.settings.links.rows.blog", fallback: "Blog")
          /// Disclaimer
          public static let disclaimer = Strings.tr("Localizable", "views.settings.links.rows.disclaimer", fallback: "Disclaimer")
          /// Home page
          public static let homePage = Strings.tr("Localizable", "views.settings.links.rows.home_page", fallback: "Home page")
          /// Join community
          public static let joinCommunity = Strings.tr("Localizable", "views.settings.links.rows.join_community", fallback: "Join community")
          /// Start a discussion
          public static let openDiscussion = Strings.tr("Localizable", "views.settings.links.rows.open_discussion", fallback: "Start a discussion")
          /// Privacy policy
          public static let privacyPolicy = Strings.tr("Localizable", "views.settings.links.rows.privacy_policy", fallback: "Privacy policy")
          /// Write a review
          public static let writeReview = Strings.tr("Localizable", "views.settings.links.rows.write_review", fallback: "Write a review")
        }
        public enum Sections {
          /// Support
          public static let support = Strings.tr("Localizable", "views.settings.links.sections.support", fallback: "Support")
          /// Web
          public static let web = Strings.tr("Localizable", "views.settings.links.sections.web", fallback: "Web")
        }
      }
      public enum SystemExtension {
        /// For the VPN to work, the app must reside in the /Applications directory, and %@ must be enabled as %@.
        /// 
        /// Open the macOS Preferences, scroll to '%@', open it and enable %@.
        public static func message(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any) -> String {
          return Strings.tr("Localizable", "views.settings.system_extension.message", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4), fallback: "For the VPN to work, the app must reside in the /Applications directory, and %@ must be enabled as %@.\n\nOpen the macOS Preferences, scroll to '%@', open it and enable %@.")
        }
        public enum Buttons {
          /// Open Preferences
          public static let `open` = Strings.tr("Localizable", "views.settings.system_extension.buttons.open", fallback: "Open Preferences")
        }
      }
    }
    public enum Tv {
      public enum ConnectionProfiles {
        public enum Header {
          /// Alternatively, you will find other options in the "Profiles" tab.
          public static let `import` = Strings.tr("Localizable", "views.tv.connection_profiles.header.import", fallback: "Alternatively, you will find other options in the \"Profiles\" tab.")
          /// Open %@ on your iOS or macOS device and enable the "%@" toggle of a profile to make it appear here.
          public static func share(_ p1: Any, _ p2: Any) -> String {
            return Strings.tr("Localizable", "views.tv.connection_profiles.header.share", String(describing: p1), String(describing: p2), fallback: "Open %@ on your iOS or macOS device and enable the \"%@\" toggle of a profile to make it appear here.")
          }
        }
      }
      public enum Profiles {
        /// Import local profile
        public static let importLocal = Strings.tr("Localizable", "views.tv.profiles.import_local", fallback: "Import local profile")
        public enum Detail {
          /// Use the long press to present the available actions for a profile.
          public static let profiles = Strings.tr("Localizable", "views.tv.profiles.detail.profiles", fallback: "Use the long press to present the available actions for a profile.")
        }
      }
      public enum WebReceiver {
        /// Scan the QR with your camera to open a web page where to upload your profile. Make sure that you are connected to the same network.
        public static let qr = Strings.tr("Localizable", "views.tv.web_receiver.qr", fallback: "Scan the QR with your camera to open a web page where to upload your profile. Make sure that you are connected to the same network.")
        /// Toggle to import a local profile into your TV with a web browser.
        public static let toggle = Strings.tr("Localizable", "views.tv.web_receiver.toggle", fallback: "Toggle to import a local profile into your TV with a web browser.")
      }
    }
    public enum Ui {
      public enum ConnectionStatus {
        ///  (on-demand)
        public static let onDemandSuffix = Strings.tr("Localizable", "views.ui.connection_status.on_demand_suffix", fallback: " (on-demand)")
      }
      public enum ModuleSend {
        /// Copy of %@
        public static func newProfileName(_ p1: Any) -> String {
          return Strings.tr("Localizable", "views.ui.module_send.new_profile_name", String(describing: p1), fallback: "Copy of %@")
        }
        /// Copy to
        public static let title = Strings.tr("Localizable", "views.ui.module_send.title", fallback: "Copy to")
      }
      public enum PurchaseRequired {
        public enum Purchase {
          /// Purchase required
          public static let help = Strings.tr("Localizable", "views.ui.purchase_required.purchase.help", fallback: "Purchase required")
        }
      }
    }
    public enum Verification {
      /// Verifying...
      public static let message = Strings.tr("Localizable", "views.verification.message", fallback: "Verifying...")
    }
    public enum Version {
      /// %@ is a project maintained by %@.
      /// 
      /// Source code is publicly available on GitHub under the GPLv3, you can find links in the home page.
      public static func extra(_ p1: Any, _ p2: Any) -> String {
        return Strings.tr("Localizable", "views.version.extra", String(describing: p1), String(describing: p2), fallback: "%@ is a project maintained by %@.\n\nSource code is publicly available on GitHub under the GPLv3, you can find links in the home page.")
      }
    }
    public enum Vpn {
      /// No servers
      public static let noServers = Strings.tr("Localizable", "views.vpn.no_servers", fallback: "No servers")
      public enum Category {
        /// All categories
        public static let any = Strings.tr("Localizable", "views.vpn.category.any", fallback: "All categories")
      }
    }
  }
  public enum WebUploader {
    /// Upload
    public static let submit = Strings.tr("Localizable", "web_uploader.submit", fallback: "Upload")
    /// Upload complete!
    public static let success = Strings.tr("Localizable", "web_uploader.success", fallback: "Upload complete!")
    /// Upload to Apple TV
    public static let title = Strings.tr("Localizable", "web_uploader.title", fallback: "Upload to Apple TV")
    public enum Errors {
      /// Upload failed:
      public static let generic = Strings.tr("Localizable", "web_uploader.errors.generic", fallback: "Upload failed:")
      /// The passcode is incorrect.
      public static let incorrectPasscode = Strings.tr("Localizable", "web_uploader.errors.incorrect_passcode", fallback: "The passcode is incorrect.")
      /// No web page exists at the given URL.
      public static let urlNotFound = Strings.tr("Localizable", "web_uploader.errors.url_not_found", fallback: "No web page exists at the given URL.")
    }
    public enum File {
      /// Browse
      public static let browse = Strings.tr("Localizable", "web_uploader.file.browse", fallback: "Browse")
      /// No file chosen
      public static let noSelection = Strings.tr("Localizable", "web_uploader.file.no_selection", fallback: "No file chosen")
      /// Select a configuration file to send
      public static let prompt = Strings.tr("Localizable", "web_uploader.file.prompt", fallback: "Select a configuration file to send")
    }
    public enum Passcode {
      /// Enter the passcode displayed on your TV
      public static let prompt = Strings.tr("Localizable", "web_uploader.passcode.prompt", fallback: "Enter the passcode displayed on your TV")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension Strings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = Bundle.module.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
// swiftlint:enable all
