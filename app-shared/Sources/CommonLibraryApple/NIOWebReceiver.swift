// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(tvOS)

import NIO
import NIOHTTP1

public final class NIOWebReceiver: WebReceiver, @unchecked Sendable {
    private let logger: AppLogger

    private let html: String

    private let port: Int

    private var channel: Channel?

    private var group: EventLoopGroup?

    public init(logger: AppLogger, htmlPath: String, stringsBundle: Bundle, port: Int) {
        self.logger = logger
        html = {
            do {
                let contents = try String(contentsOfFile: htmlPath)
                let template = HTMLTemplate(html: contents)
                return template.withLocalizedKeys(in: stringsBundle)
            } catch {
                fatalError("Unable to load web uploader HTML template")
            }
        }()
        self.port = port
    }

    // onReceive(filename, content)
    public func start(passcode: String?, onReceive: @escaping @Sendable (String, String) -> Void) throws -> URL {
        guard channel == nil else {
            logger.log(.web, .error, "Web server is already started")
            throw WebReceiverError()
        }
        guard let host = firstIPv4Address(withInterfacePrefix: "en") else {
            logger.log(.web, .error, "Web server has no IPv4 Ethernet addresses to listen on")
            throw WebReceiverError()
        }
        do {
            let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
            let bootstrap = ServerBootstrap(group: group)
                .serverChannelOption(.backlog, value: 256)
                .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
                .childChannelInitializer { channel in
                    channel.pipeline.configureHTTPServerPipeline().flatMap { [weak self] in
                        guard let self else {
                            return channel.eventLoop.makeSucceededFuture(())
                        }
                        return channel.pipeline.addHandler(
                            NIOWebReceiverHandler(
                                html: html,
                                passcode: passcode,
                                onReceive: onReceive
                            )
                        )
                    }
                }
                .childChannelOption(.socketOption(.so_reuseaddr), value: 1)

            channel = try bootstrap.bind(host: host, port: port).wait()
            self.group = group
        } catch {
            logger.log(.web, .error, "Web server could not bind: \(error)")
            throw WebReceiverError(error)
        }
        guard let address = channel?.localAddress?.ipAddress else {
            logger.log(.web, .error, "Web server has no bound IP address")
            throw WebReceiverError()
        }
        guard let url = URL(string: "http://\(address):\(port)") else {
            logger.log(.web, .error, "Web server URL could not be built")
            throw WebReceiverError()
        }
        logger.log(.web, .notice, "Web server did start: \(url)")
        return url
    }

    public func stop() {
        guard let channel else {
            logger.log(.web, .error, "Web server is not started")
            return
        }
        defer {
            self.channel = nil
            self.group = nil
        }
        do {
            try channel.close().wait()
            try group?.syncShutdownGracefully()
            logger.log(.web, .notice, "Web server did stop")
        } catch {
            logger.log(.web, .error, "Unable to stop web server: \(error)")
        }
    }
}

private extension NIOWebReceiver {
    enum InvalidIPv4Error: Error {
        case wrongFamily

        case interfaceDown

        case loopbackInterface

        case interfaceName(String)

        case notPrivate
    }

    func firstIPv4Address(withInterfacePrefix prefix: String) -> String? {
        var firstAddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&firstAddr) == 0, let firstAddr else {
            return nil
        }

        var ipAddress: String?
        var ptr = firstAddr

        while let cIfName = ptr.pointee.ifa_name {
            let addr = ptr.pointee.ifa_addr.pointee
            let flags = ptr.pointee.ifa_flags

            do {
                // IPv4
                guard addr.sa_family == UInt8(AF_INET) else {
                    throw InvalidIPv4Error.wrongFamily
                }
                // interface up
                guard (flags & UInt32(IFF_UP)) != 0 else {
                    throw InvalidIPv4Error.interfaceDown
                }
                // not loopback
                guard (flags & UInt32(IFF_LOOPBACK)) == 0 else {
                    throw InvalidIPv4Error.loopbackInterface
                }
                // matching prefix
                let ifName = String(cString: cIfName)
                guard ifName.hasPrefix(prefix) else {
                    throw InvalidIPv4Error.interfaceName(ifName)
                }
                // A/B/C class
                let sinPtr = UnsafeRawPointer(ptr.pointee.ifa_addr)
                    .assumingMemoryBound(to: sockaddr_in.self)
                let sinAddr = sinPtr.pointee.sin_addr
                let ipV4 = CFSwapInt32BigToHost(sinAddr.s_addr)
                guard ipV4.isPrivateNetwork else {
                    throw InvalidIPv4Error.notPrivate
                }

                var addrCopy = addr
                var cIPAddress = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(
                    &addrCopy,
                    socklen_t(ptr.pointee.ifa_addr.pointee.sa_len),
                    &cIPAddress,
                    socklen_t(cIPAddress.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )
                ipAddress = String(cString: cIPAddress)
                assert(
                    !ipAddress!.starts(with: "169.254"),
                    "Link-local IPv4 address should have failed at .isPrivateNetwork"
                )

                // stop at first success
                break
            } catch {
                logger.log(.web, .debug, "Skip invalid interface: \(error)")
            }

            // leave if no more addresses
            guard let next = ptr.pointee.ifa_next else {
                break
            }
            ptr = next
        }

        freeifaddrs(firstAddr)
        return ipAddress
    }
}

private extension UInt32 {
    var isPrivateNetwork: Bool {
        // 10.0.0.0/8
        if (self & 0xFF000000) == 0x0A000000 { return true }
        // 172.16.0.0/12
        if (self & 0xFFF00000) == 0xAC100000 { return true }
        // 192.168.0.0/16
        if (self & 0xFFFF0000) == 0xC0A80000 { return true }
        return false
    }
}

#endif
