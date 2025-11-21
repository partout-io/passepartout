// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public struct Constants: Decodable, Sendable {
        public struct Containers: Decodable, Sendable {
            public let local: String

            public let remote: String

            public let backup: String
        }

        public struct Websites: Decodable, Sendable {
            public let home: URL

            public var api: URL {
                home.appendingPathComponent("api/")
            }

            public var faq: URL {
                home.appendingPathComponent("faq/")
            }

            public var blog: URL {
                home.appendingPathComponent("blog/")
            }

            public var disclaimer: URL {
                home.appendingPathComponent("disclaimer/")
            }

            public var privacyPolicy: URL {
                home.appendingPathComponent("privacy/")
            }

            public var donate: URL {
                home.appendingPathComponent("donate/")
            }

            public var config: URL {
                home.appendingPathComponent("config/v1/bundle.json")
            }

            public var betaConfig: URL {
                home.appendingPathComponent("config/v1/bundle-beta.json")
            }

            public let subreddit: URL

            public let eula: URL

            public let appStoreDownload: URL

            public let macDownload: URL

            public let configTTL: TimeInterval
        }

        public struct GitHub: Decodable, Sendable {
            public func urlForIssue(_ issue: Int) -> URL {
                issues.appending(path: issue.description)
            }

            public func urlForChangelog(ofVersion version: String) -> URL {
                raw.appending(path: "refs/tags/v\(version)/CHANGELOG.txt")
            }

            public let discussions: URL

            public let issues: URL

            public let raw: URL

            public let latestRelease: URL
        }

        public struct Emails: Decodable, Sendable {
            private struct Recipients: Decodable, Sendable {
                let issues: String

                let beta: String
            }

            public let domain: String

            private let recipients: Recipients

            public var issues: String {
                email(to: recipients.issues)
            }

            public var beta: String {
                email(to: recipients.beta)
            }

            private func email(to: String) -> String {
                [to, domain].joined(separator: "@")
            }
        }

        public struct Formats: Decodable, Sendable {
            public let timestamp: String
        }

        public struct Tunnel: Decodable, Sendable {
            public struct Verification: Decodable, Sendable {
                public struct Parameters: Decodable, Sendable {
                    public let delay: TimeInterval

                    public let interval: TimeInterval

                    public let attempts: Int

                    public let retryInterval: TimeInterval
                }

                public let production: Parameters

                public let beta: Parameters
            }

            public let profileTitleFormat: String

            public let refreshInterval: TimeInterval

            public let dnsFallbackServers: [String]

            public let verification: Verification

            public func verificationDelayMinutes(isBeta: Bool) -> Int {
                let params = verificationParameters(isBeta: isBeta)
                return Int(params.delay / 60.0)
            }

            public func verificationParameters(isBeta: Bool) -> Verification.Parameters {
                isBeta ? verification.beta : verification.production
            }
        }

        public struct API: Decodable, Sendable {
            public let timeoutInterval: TimeInterval

            public let versionRateLimit: TimeInterval

            public let refreshInfrastructureRateLimit: TimeInterval
        }

        public struct IAP: Decodable, Sendable {
            public let productsTimeoutInterval: TimeInterval

            public let receiptInvalidationInterval: TimeInterval
        }

        public struct WebReceiver: Decodable, Sendable {
            public let port: Int

            public let passcodeLength: Int
        }

        public struct Log: Decodable, Sendable {
            public struct Formatter: Decodable, Sendable {
                enum CodingKeys: CodingKey {
                    case timestamp

                    case message
                }

                private let timestampFormatter: DateFormatter

                private let message: String

                public init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    let timestampFormat = try container.decode(String.self, forKey: .timestamp)
                    timestampFormatter = DateFormatter()
                    timestampFormatter.dateFormat = timestampFormat
                    message = try container.decode(String.self, forKey: .message)
                }

                public func formattedLine(_ line: DebugLog.Line) -> String {
                    let formattedTimestamp = timestampFormatter.string(from: line.timestamp)
                    return String(format: message, formattedTimestamp, line.message)
                }
            }

            public let formatter: Formatter

            public let appPath: String

            public let tunnelPath: String

            public let sinceLast: TimeInterval

            public let options: LocalLogger.Options
        }

        public let deviceIdLength: Int

        public let containers: Containers

        public let websites: Websites

        public let github: GitHub

        public let emails: Emails

        public let formats: Formats

        public let tunnel: Tunnel

        public let api: API

        public let iap: IAP

        public let webReceiver: WebReceiver

        public let log: Log
    }
}
