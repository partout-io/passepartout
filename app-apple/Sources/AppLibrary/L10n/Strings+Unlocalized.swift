// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension Strings {
    public enum Unlocalized {
        public enum OpenVPN {
            public enum Placeholders {
                public static let endpoint = "1.1.1.1:2222"
            }

            public enum XOR: String {
                case xormask

                case xorptrpos

                case reverse

                case obfuscate
            }

            public static let compLZO = "--comp-lzo"

            public static let compress = "--compress"

            public static let lzo = "LZO"
        }

        public enum Placeholders {
            public static let hostname = "example.com"

            public static let dohURL = "https://1.2.3.4/some-query"

            public static let dotHostname = "dns-hostname.com"

            public static let ipV4DNS = "1.1.1.1"

            public static let proxyPort = "1080"

            public static let mtu = "1500"

            public static let pacURL = "http://proxy.com/pac.url"

            public static let keepAlive = "30"

            public static let webUploaderPort = "5000"

            public static let webUploaderPasscode = "123456"
        }

        public enum Issues {
            public static let subject = "\(appName) - Report issue"

            public static let attachmentMimeType = "text/plain"
        }

        public static let appName = "Passepartout"

        public static let appleTV = "Apple TV"

        public static let authorName = "Davide De Rosa (keeshux)"

        public static let ca = "CA"

        public static let changelog = "CHANGELOG"

        public static let dns = "DNS"

        public static let eula = "EULA"

        public static let faq = "FAQ"

        public static let http = "HTTP"

        public static let https = "HTTPS"

        public static let httpProxy = "HTTP Proxy"

        public static let iCloud = "iCloud"

        public static let ip = "IP"

        public static let ipv4 = "IPv4"

        public static let ipv6 = "IPv6"

        public static let longDash = "—"

        public static let mtu = "MTU"

        public static let openVPN = "OpenVPN"

        public static let otp = "OTP"

        public static let pac = "PAC"

        public static let proxy = "Proxy"

        public static let reddit = "Reddit"

        public static let tls = "TLS"

        public static let url = "URL"

        public static let uuid = "UUID"

        public static let wifi = "Wi-Fi"

        public static let wireGuard = "WireGuard"

        public static let xor = "XOR"
    }
}

extension Strings.Unlocalized.Placeholders {
    public static func ipDestination(forFamily family: Address.Family) -> String {
        switch family {
        case .v4:
            return "192.168.15.0/24"
        case .v6:
            return "fdbd:dcf8:d811:af73::/64"
        }
    }

    public static func ipAddress(forFamily family: Address.Family) -> String {
        switch family {
        case .v4:
            return "192.168.15.1"
        case .v6:
            return "fdbd:dcf8:d811:af73::1"
        }
    }

    public static let proxyIPv4Address = ipAddress(forFamily: .v4)
}
