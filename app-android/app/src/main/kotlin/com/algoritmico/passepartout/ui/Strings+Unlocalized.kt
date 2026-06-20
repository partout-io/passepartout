// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.ui

object Strings {
    object Unlocalized {
        object OpenVPN {
            object Placeholders {
                const val endpoint = "1.1.1.1:2222"
            }

            enum class XOR(val value: String) {
                xormask("xormask"),
                xorptrpos("xorptrpos"),
                reverse("reverse"),
                obfuscate("obfuscate")
            }

            const val compLZO = "--comp-lzo"
            const val compress = "--compress"
            const val lzo = "LZO"
        }

        object Placeholders {
            enum class AddressFamily {
                IPv4,
                IPv6
            }

            const val hostname = "example.com"
            const val dohURL = "https://1.2.3.4/some-query"
            const val dotHostname = "dns-hostname.com"
            const val ipV4DNS = "1.1.1.1"
            const val proxyPort = "1080"
            const val mtu = "1500"
            const val pacURL = "http://proxy.com/pac.url"
            const val keepAlive = "30"
            const val webUploaderPort = "5000"
            const val webUploaderPasscode = "123456"
            val proxyIPv4Address = ipAddress(AddressFamily.IPv4)

            fun ipDestination(family: AddressFamily): String {
                return when (family) {
                    AddressFamily.IPv4 -> "192.168.15.0/24"
                    AddressFamily.IPv6 -> "fdbd:dcf8:d811:af73::/64"
                }
            }

            fun ipAddress(family: AddressFamily): String {
                return when (family) {
                    AddressFamily.IPv4 -> "192.168.15.1"
                    AddressFamily.IPv6 -> "fdbd:dcf8:d811:af73::1"
                }
            }
        }

        object Issues {
            val subject = "$appName/Android - Report issue"
            const val attachmentMimeType = "text/plain"
        }

        const val appName = "Passepartout"
        const val appleTV = "Apple TV"
        const val authorName = "Davide De Rosa (keeshux)"
        const val ca = "CA"
        const val changelog = "CHANGELOG"
        const val dns = "DNS"
        const val eula = "EULA"
        const val faq = "FAQ"
        const val http = "HTTP"
        const val https = "HTTPS"
        const val httpProxy = "HTTP Proxy"
        const val iCloud = "iCloud"
        const val ip = "IP"
        const val ipv4 = "IPv4"
        const val ipv6 = "IPv6"
        const val longDash = "\u2014"
        const val mtu = "MTU"
        const val openVPN = "OpenVPN"
        const val otp = "OTP"
        const val pac = "PAC"
        const val proxy = "Proxy"
        const val tls = "TLS"
        const val url = "URL"
        const val uuid = "UUID"
        const val wifi = "Wi-Fi"
        const val wireGuard = "WireGuard"
        const val xor = "XOR"
    }
}
