// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let quicktypeAppBundle = try? JSONDecoder().decode(QuicktypeAppBundle.self, from: jsonData)
//   let quicktypeAppConfiguration = try? JSONDecoder().decode(QuicktypeAppConfiguration.self, from: jsonData)
//   let quicktypeAppConstants = try? JSONDecoder().decode(QuicktypeAppConstants.self, from: jsonData)
//   let quicktypeAppFeature = try? JSONDecoder().decode(QuicktypeAppFeature.self, from: jsonData)
//   let quicktypeAppProfileHeader = try? JSONDecoder().decode(QuicktypeAppProfileHeader.self, from: jsonData)
//   let quicktypeAppTunnelInfo = try? JSONDecoder().decode(QuicktypeAppTunnelInfo.self, from: jsonData)
//   let quicktypeAppTunnelStatus = try? JSONDecoder().decode(QuicktypeAppTunnelStatus.self, from: jsonData)
//   let quicktypeAppUserLevel = try? JSONDecoder().decode(QuicktypeAppUserLevel.self, from: jsonData)
//   let quicktypeConfigEventRefresh = try? JSONDecoder().decode(QuicktypeConfigEventRefresh.self, from: jsonData)
//   let quicktypeConfigFlag = try? JSONDecoder().decode(QuicktypeConfigFlag.self, from: jsonData)
//   let quicktypeCredits = try? JSONDecoder().decode(QuicktypeCredits.self, from: jsonData)
//   let quicktypeDistributionTarget = try? JSONDecoder().decode(QuicktypeDistributionTarget.self, from: jsonData)
//   let quicktypeIAPEventEligibleFeatures = try? JSONDecoder().decode(QuicktypeIAPEventEligibleFeatures.self, from: jsonData)
//   let quicktypeIAPEventLoadReceipt = try? JSONDecoder().decode(QuicktypeIAPEventLoadReceipt.self, from: jsonData)
//   let quicktypeIAPEventNewReceipt = try? JSONDecoder().decode(QuicktypeIAPEventNewReceipt.self, from: jsonData)
//   let quicktypeIAPEventStatus = try? JSONDecoder().decode(QuicktypeIAPEventStatus.self, from: jsonData)
//   let quicktypeOriginalPurchase = try? JSONDecoder().decode(QuicktypeOriginalPurchase.self, from: jsonData)
//   let quicktypeProfileEventChangeRemoteImporting = try? JSONDecoder().decode(QuicktypeProfileEventChangeRemoteImporting.self, from: jsonData)
//   let quicktypeProfileEventLocalProfiles = try? JSONDecoder().decode(QuicktypeProfileEventLocalProfiles.self, from: jsonData)
//   let quicktypeProfileEventReady = try? JSONDecoder().decode(QuicktypeProfileEventReady.self, from: jsonData)
//   let quicktypeProfileEventRefresh = try? JSONDecoder().decode(QuicktypeProfileEventRefresh.self, from: jsonData)
//   let quicktypeProfileEventSave = try? JSONDecoder().decode(QuicktypeProfileEventSave.self, from: jsonData)
//   let quicktypeProfileEventStartRemoteImport = try? JSONDecoder().decode(QuicktypeProfileEventStartRemoteImport.self, from: jsonData)
//   let quicktypeProfileEventStopRemoteImport = try? JSONDecoder().decode(QuicktypeProfileEventStopRemoteImport.self, from: jsonData)
//   let quicktypeProfileSharingFlag = try? JSONDecoder().decode(QuicktypeProfileSharingFlag.self, from: jsonData)
//   let quicktypeProviderInfo = try? JSONDecoder().decode(QuicktypeProviderInfo.self, from: jsonData)
//   let quicktypeSemanticVersion = try? JSONDecoder().decode(QuicktypeSemanticVersion.self, from: jsonData)
//   let quicktypeTimestamp = try? JSONDecoder().decode(QuicktypeTimestamp.self, from: jsonData)
//   let quicktypeTunnelEventDataCount = try? JSONDecoder().decode(QuicktypeTunnelEventDataCount.self, from: jsonData)
//   let quicktypeTunnelEventRefresh = try? JSONDecoder().decode(QuicktypeTunnelEventRefresh.self, from: jsonData)
//   let quicktypeVersionEventNew = try? JSONDecoder().decode(QuicktypeVersionEventNew.self, from: jsonData)
//   let quicktypeVersionRelease = try? JSONDecoder().decode(QuicktypeVersionRelease.self, from: jsonData)
//   let quicktypeWebFileUpload = try? JSONDecoder().decode(QuicktypeWebFileUpload.self, from: jsonData)
//   let quicktypeWebReceiverEventNewUpload = try? JSONDecoder().decode(QuicktypeWebReceiverEventNewUpload.self, from: jsonData)
//   let quicktypeWebReceiverEventStart = try? JSONDecoder().decode(QuicktypeWebReceiverEventStart.self, from: jsonData)
//   let quicktypeWebReceiverEventStop = try? JSONDecoder().decode(QuicktypeWebReceiverEventStop.self, from: jsonData)
//   let quicktypeWebReceiverEventUploadFailure = try? JSONDecoder().decode(QuicktypeWebReceiverEventUploadFailure.self, from: jsonData)
//   let quicktypeWebsiteWithPasscode = try? JSONDecoder().decode(QuicktypeWebsiteWithPasscode.self, from: jsonData)

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Partout

// MARK: - QuicktypeAppConfiguration
public struct QuicktypeAppConfiguration: Codable, Equatable, Sendable {
    public let bundle: QuicktypeAppBundle
    public let constants: QuicktypeAppConstants

    public enum CodingKeys: String, CodingKey {
        case bundle = "bundle"
        case constants = "constants"
    }

    public init(bundle: QuicktypeAppBundle, constants: QuicktypeAppConstants) {
        self.bundle = bundle
        self.constants = constants
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppBundle
public struct QuicktypeAppBundle: Codable, Equatable, Sendable {
    public let appLogPath: String
    public let appLogsURL: URL
    public let buildNumber: Int
    public let bundleStrings: [String: String]
    public let customUserLevel: QuicktypeAppUserLevel?
    public let displayName: String
    public let distributionTarget: QuicktypeDistributionTarget
    public let reviewURL: URL?
    public let tunnelLogPath: String
    public let tunnelLogsURL: URL
    public let versionNumber: String

    public enum CodingKeys: String, CodingKey {
        case appLogPath = "appLogPath"
        case appLogsURL = "appLogsURL"
        case buildNumber = "buildNumber"
        case bundleStrings = "bundleStrings"
        case customUserLevel = "customUserLevel"
        case displayName = "displayName"
        case distributionTarget = "distributionTarget"
        case reviewURL = "reviewURL"
        case tunnelLogPath = "tunnelLogPath"
        case tunnelLogsURL = "tunnelLogsURL"
        case versionNumber = "versionNumber"
    }

    public init(appLogPath: String, appLogsURL: URL, buildNumber: Int, bundleStrings: [String: String], customUserLevel: QuicktypeAppUserLevel?, displayName: String, distributionTarget: QuicktypeDistributionTarget, reviewURL: URL?, tunnelLogPath: String, tunnelLogsURL: URL, versionNumber: String) {
        self.appLogPath = appLogPath
        self.appLogsURL = appLogsURL
        self.buildNumber = buildNumber
        self.bundleStrings = bundleStrings
        self.customUserLevel = customUserLevel
        self.displayName = displayName
        self.distributionTarget = distributionTarget
        self.reviewURL = reviewURL
        self.tunnelLogPath = tunnelLogPath
        self.tunnelLogsURL = tunnelLogsURL
        self.versionNumber = versionNumber
    }
}

public enum QuicktypeAppUserLevel: String, Codable, Equatable, Sendable {
    case beta = "beta"
    case complete = "complete"
    case essentials = "essentials"
    case freemium = "freemium"
    case undefined = "undefined"
}

public enum QuicktypeDistributionTarget: String, Codable, Equatable, Sendable {
    case appStore = "appStore"
    case developerID = "developerID"
    case enterprise = "enterprise"
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstants
public struct QuicktypeAppConstants: Codable, Equatable, Sendable {
    public let api: QuicktypeAppConstantsAPI
    public let containers: QuicktypeAppConstantsContainers
    public let deviceIDLength: Int
    public let emails: QuicktypeAppConstantsEmails
    public let formats: QuicktypeAppConstantsFormats
    public let github: QuicktypeAppConstantsGitHub
    public let iap: QuicktypeAppConstantsIAP
    public let log: QuicktypeAppConstantsLog
    public let tunnel: QuicktypeAppConstantsTunnel
    public let webReceiver: QuicktypeAppConstantsWebReceiver
    public let websites: QuicktypeAppConstantsWebsites

    public enum CodingKeys: String, CodingKey {
        case api = "api"
        case containers = "containers"
        case deviceIDLength = "deviceIdLength"
        case emails = "emails"
        case formats = "formats"
        case github = "github"
        case iap = "iap"
        case log = "log"
        case tunnel = "tunnel"
        case webReceiver = "webReceiver"
        case websites = "websites"
    }

    public init(api: QuicktypeAppConstantsAPI, containers: QuicktypeAppConstantsContainers, deviceIDLength: Int, emails: QuicktypeAppConstantsEmails, formats: QuicktypeAppConstantsFormats, github: QuicktypeAppConstantsGitHub, iap: QuicktypeAppConstantsIAP, log: QuicktypeAppConstantsLog, tunnel: QuicktypeAppConstantsTunnel, webReceiver: QuicktypeAppConstantsWebReceiver, websites: QuicktypeAppConstantsWebsites) {
        self.api = api
        self.containers = containers
        self.deviceIDLength = deviceIDLength
        self.emails = emails
        self.formats = formats
        self.github = github
        self.iap = iap
        self.log = log
        self.tunnel = tunnel
        self.webReceiver = webReceiver
        self.websites = websites
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsAPI
public struct QuicktypeAppConstantsAPI: Codable, Equatable, Sendable {
    public let refreshInfrastructureRateLimit: Double
    public let timeoutInterval: Double
    public let versionRateLimit: Double

    public enum CodingKeys: String, CodingKey {
        case refreshInfrastructureRateLimit = "refreshInfrastructureRateLimit"
        case timeoutInterval = "timeoutInterval"
        case versionRateLimit = "versionRateLimit"
    }

    public init(refreshInfrastructureRateLimit: Double, timeoutInterval: Double, versionRateLimit: Double) {
        self.refreshInfrastructureRateLimit = refreshInfrastructureRateLimit
        self.timeoutInterval = timeoutInterval
        self.versionRateLimit = versionRateLimit
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsContainers
public struct QuicktypeAppConstantsContainers: Codable, Equatable, Sendable {
    public let backup: String
    public let local: String
    public let remote: String

    public enum CodingKeys: String, CodingKey {
        case backup = "backup"
        case local = "local"
        case remote = "remote"
    }

    public init(backup: String, local: String, remote: String) {
        self.backup = backup
        self.local = local
        self.remote = remote
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsEmails
public struct QuicktypeAppConstantsEmails: Codable, Equatable, Sendable {
    public let domain: String
    public let recipients: QuicktypeAppConstantsEmailsRecipients

    public enum CodingKeys: String, CodingKey {
        case domain = "domain"
        case recipients = "recipients"
    }

    public init(domain: String, recipients: QuicktypeAppConstantsEmailsRecipients) {
        self.domain = domain
        self.recipients = recipients
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsEmailsRecipients
public struct QuicktypeAppConstantsEmailsRecipients: Codable, Equatable, Sendable {
    public let beta: String
    public let issues: String

    public enum CodingKeys: String, CodingKey {
        case beta = "beta"
        case issues = "issues"
    }

    public init(beta: String, issues: String) {
        self.beta = beta
        self.issues = issues
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsFormats
public struct QuicktypeAppConstantsFormats: Codable, Equatable, Sendable {
    public let timestamp: String

    public enum CodingKeys: String, CodingKey {
        case timestamp = "timestamp"
    }

    public init(timestamp: String) {
        self.timestamp = timestamp
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsGitHub
public struct QuicktypeAppConstantsGitHub: Codable, Equatable, Sendable {
    public let discussionsURL: URL
    public let issuesURL: URL
    public let latestReleaseURL: URL
    public let rawURL: URL

    public enum CodingKeys: String, CodingKey {
        case discussionsURL = "discussionsURL"
        case issuesURL = "issuesURL"
        case latestReleaseURL = "latestReleaseURL"
        case rawURL = "rawURL"
    }

    public init(discussionsURL: URL, issuesURL: URL, latestReleaseURL: URL, rawURL: URL) {
        self.discussionsURL = discussionsURL
        self.issuesURL = issuesURL
        self.latestReleaseURL = latestReleaseURL
        self.rawURL = rawURL
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsIAP
public struct QuicktypeAppConstantsIAP: Codable, Equatable, Sendable {
    public let productsTimeoutInterval: Double
    public let receiptInvalidationInterval: Double

    public enum CodingKeys: String, CodingKey {
        case productsTimeoutInterval = "productsTimeoutInterval"
        case receiptInvalidationInterval = "receiptInvalidationInterval"
    }

    public init(productsTimeoutInterval: Double, receiptInvalidationInterval: Double) {
        self.productsTimeoutInterval = productsTimeoutInterval
        self.receiptInvalidationInterval = receiptInvalidationInterval
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsLog
public struct QuicktypeAppConstantsLog: Codable, Equatable, Sendable {
    public let formatter: QuicktypeAppConstantsLogFormatter
    public let options: QuicktypeAppConstantsLogOptions
    public let sinceLast: Double

    public enum CodingKeys: String, CodingKey {
        case formatter = "formatter"
        case options = "options"
        case sinceLast = "sinceLast"
    }

    public init(formatter: QuicktypeAppConstantsLogFormatter, options: QuicktypeAppConstantsLogOptions, sinceLast: Double) {
        self.formatter = formatter
        self.options = options
        self.sinceLast = sinceLast
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsLogFormatter
public struct QuicktypeAppConstantsLogFormatter: Codable, Equatable, Sendable {
    public let message: String
    public let timestamp: String

    public enum CodingKeys: String, CodingKey {
        case message = "message"
        case timestamp = "timestamp"
    }

    public init(message: String, timestamp: String) {
        self.message = message
        self.timestamp = timestamp
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsLogOptions
public struct QuicktypeAppConstantsLogOptions: Codable, Equatable, Sendable {
    /// Optional maximum age in seconds
    public let maxAge: Double?
    public let maxBufferedLines: Int
    /// DebugLog.Level (0=debug, 1=info, 2=warning, 3=error)
    public let maxLevel: Int
    /// Maximum size in bytes
    public let maxSize: Int

    public enum CodingKeys: String, CodingKey {
        case maxAge = "maxAge"
        case maxBufferedLines = "maxBufferedLines"
        case maxLevel = "maxLevel"
        case maxSize = "maxSize"
    }

    public init(maxAge: Double?, maxBufferedLines: Int, maxLevel: Int, maxSize: Int) {
        self.maxAge = maxAge
        self.maxBufferedLines = maxBufferedLines
        self.maxLevel = maxLevel
        self.maxSize = maxSize
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsTunnel
public struct QuicktypeAppConstantsTunnel: Codable, Equatable, Sendable {
    public let dnsFallbackServers: [String]
    public let profileTitleFormat: String
    public let refreshInterval: Double
    public let verification: QuicktypeAppConstantsTunnelVerification

    public enum CodingKeys: String, CodingKey {
        case dnsFallbackServers = "dnsFallbackServers"
        case profileTitleFormat = "profileTitleFormat"
        case refreshInterval = "refreshInterval"
        case verification = "verification"
    }

    public init(dnsFallbackServers: [String], profileTitleFormat: String, refreshInterval: Double, verification: QuicktypeAppConstantsTunnelVerification) {
        self.dnsFallbackServers = dnsFallbackServers
        self.profileTitleFormat = profileTitleFormat
        self.refreshInterval = refreshInterval
        self.verification = verification
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsTunnelVerification
public struct QuicktypeAppConstantsTunnelVerification: Codable, Equatable, Sendable {
    public let beta: QuicktypeAppConstantsTunnelVerificationParameters
    public let production: QuicktypeAppConstantsTunnelVerificationParameters

    public enum CodingKeys: String, CodingKey {
        case beta = "beta"
        case production = "production"
    }

    public init(beta: QuicktypeAppConstantsTunnelVerificationParameters, production: QuicktypeAppConstantsTunnelVerificationParameters) {
        self.beta = beta
        self.production = production
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsTunnelVerificationParameters
public struct QuicktypeAppConstantsTunnelVerificationParameters: Codable, Equatable, Sendable {
    public let attempts: Int
    public let delay: Double
    public let interval: Double
    public let retryInterval: Double

    public enum CodingKeys: String, CodingKey {
        case attempts = "attempts"
        case delay = "delay"
        case interval = "interval"
        case retryInterval = "retryInterval"
    }

    public init(attempts: Int, delay: Double, interval: Double, retryInterval: Double) {
        self.attempts = attempts
        self.delay = delay
        self.interval = interval
        self.retryInterval = retryInterval
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsWebReceiver
public struct QuicktypeAppConstantsWebReceiver: Codable, Equatable, Sendable {
    public let passcodeLength: Int
    public let port: Int

    public enum CodingKeys: String, CodingKey {
        case passcodeLength = "passcodeLength"
        case port = "port"
    }

    public init(passcodeLength: Int, port: Int) {
        self.passcodeLength = passcodeLength
        self.port = port
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppConstantsWebsites
public struct QuicktypeAppConstantsWebsites: Codable, Equatable, Sendable {
    public let appStoreDownloadURL: URL
    public let configTTL: Double
    public let eulaURL: URL
    public let homeURL: URL
    public let macDownloadURL: URL
    public let subredditURL: URL

    public enum CodingKeys: String, CodingKey {
        case appStoreDownloadURL = "appStoreDownloadURL"
        case configTTL = "configTTL"
        case eulaURL = "eulaURL"
        case homeURL = "homeURL"
        case macDownloadURL = "macDownloadURL"
        case subredditURL = "subredditURL"
    }

    public init(appStoreDownloadURL: URL, configTTL: Double, eulaURL: URL, homeURL: URL, macDownloadURL: URL, subredditURL: URL) {
        self.appStoreDownloadURL = appStoreDownloadURL
        self.configTTL = configTTL
        self.eulaURL = eulaURL
        self.homeURL = homeURL
        self.macDownloadURL = macDownloadURL
        self.subredditURL = subredditURL
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeConfigEventRefresh
public struct QuicktypeConfigEventRefresh: Codable, Equatable, Sendable {
    public let data: [String: JSON]
    public let flags: [QuicktypeConfigFlag]

    public enum CodingKeys: String, CodingKey {
        case data = "data"
        case flags = "flags"
    }

    public init(data: [String: JSON], flags: [QuicktypeConfigFlag]) {
        self.data = data
        self.flags = flags
    }
}

public enum QuicktypeConfigFlag: String, Codable, Equatable, Sendable {
    case allowsRelaxedVerification = "allowsRelaxedVerification"
    case appNotWorking = "appNotWorking"
    case neSocketTCP = "neSocketTCP"
    case neSocketUDP = "neSocketUDP"
    case unknown = "unknown"
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeCredits
public struct QuicktypeCredits: Codable, Equatable, Sendable {
    public let licenses: [QuicktypeLicense]
    public let notices: [QuicktypeNotice]
    public let translations: [String: [String]]

    public enum CodingKeys: String, CodingKey {
        case licenses = "licenses"
        case notices = "notices"
        case translations = "translations"
    }

    public init(licenses: [QuicktypeLicense], notices: [QuicktypeNotice], translations: [String: [String]]) {
        self.licenses = licenses
        self.notices = notices
        self.translations = translations
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeLicense
public struct QuicktypeLicense: Codable, Equatable, Sendable {
    public let licenseName: String
    public let licenseURL: URL
    public let name: String

    public enum CodingKeys: String, CodingKey {
        case licenseName = "licenseName"
        case licenseURL = "licenseURL"
        case name = "name"
    }

    public init(licenseName: String, licenseURL: URL, name: String) {
        self.licenseName = licenseName
        self.licenseURL = licenseURL
        self.name = name
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeNotice
public struct QuicktypeNotice: Codable, Equatable, Sendable {
    public let message: String
    public let name: String

    public enum CodingKeys: String, CodingKey {
        case message = "message"
        case name = "name"
    }

    public init(message: String, name: String) {
        self.message = message
        self.name = name
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeIAPEventEligibleFeatures
public struct QuicktypeIAPEventEligibleFeatures: Codable, Equatable, Sendable {
    public let features: [QuicktypeAppFeature]
    public let forComplete: Bool
    public let forFeedback: Bool

    public enum CodingKeys: String, CodingKey {
        case features = "features"
        case forComplete = "forComplete"
        case forFeedback = "forFeedback"
    }

    public init(features: [QuicktypeAppFeature], forComplete: Bool, forFeedback: Bool) {
        self.features = features
        self.forComplete = forComplete
        self.forFeedback = forFeedback
    }
}

public enum QuicktypeAppFeature: String, Codable, Equatable, Sendable {
    case appleTV = "appleTV"
    case dns = "dns"
    case httpProxy = "httpProxy"
    case onDemand = "onDemand"
    case otp = "otp"
    case providers = "providers"
    case routing = "routing"
    case sharing = "sharing"
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeIAPEventLoadReceipt
public struct QuicktypeIAPEventLoadReceipt: Codable, Equatable, Sendable {
    public let isLoading: Bool

    public enum CodingKeys: String, CodingKey {
        case isLoading = "isLoading"
    }

    public init(isLoading: Bool) {
        self.isLoading = isLoading
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeIAPEventNewReceipt
public struct QuicktypeIAPEventNewReceipt: Codable, Equatable, Sendable {
    public let isBeta: Bool
    public let originalPurchase: QuicktypeOriginalPurchase?
    public let products: [String]

    public enum CodingKeys: String, CodingKey {
        case isBeta = "isBeta"
        case originalPurchase = "originalPurchase"
        case products = "products"
    }

    public init(isBeta: Bool, originalPurchase: QuicktypeOriginalPurchase?, products: [String]) {
        self.isBeta = isBeta
        self.originalPurchase = originalPurchase
        self.products = products
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeOriginalPurchase
public struct QuicktypeOriginalPurchase: Codable, Equatable, Sendable {
    public let buildNumber: Int
    public let purchaseDate: String

    public enum CodingKeys: String, CodingKey {
        case buildNumber = "buildNumber"
        case purchaseDate = "purchaseDate"
    }

    public init(buildNumber: Int, purchaseDate: String) {
        self.buildNumber = buildNumber
        self.purchaseDate = purchaseDate
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeIAPEventStatus
public struct QuicktypeIAPEventStatus: Codable, Equatable, Sendable {
    public let isEnabled: Bool

    public enum CodingKeys: String, CodingKey {
        case isEnabled = "isEnabled"
    }

    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventChangeRemoteImporting
public struct QuicktypeProfileEventChangeRemoteImporting: Codable, Equatable, Sendable {
    public let isImporting: Bool

    public enum CodingKeys: String, CodingKey {
        case isImporting = "isImporting"
    }

    public init(isImporting: Bool) {
        self.isImporting = isImporting
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventLocalProfiles
public struct QuicktypeProfileEventLocalProfiles: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventReady
public struct QuicktypeProfileEventReady: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventRefresh
public struct QuicktypeProfileEventRefresh: Codable, Equatable, Sendable {
    public let headers: [String: QuicktypeAppProfileHeader]

    public enum CodingKeys: String, CodingKey {
        case headers = "headers"
    }

    public init(headers: [String: QuicktypeAppProfileHeader]) {
        self.headers = headers
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppProfileHeader
public struct QuicktypeAppProfileHeader: Codable, Equatable, Sendable {
    public let fingerprint: String
    public let id: String
    public let moduleTypes: [QuicktypeModuleType]
    public let name: String
    public let primaryModuleType: QuicktypeModuleType?
    public let providerInfo: QuicktypeProviderInfo?
    public let requiredFeatures: [QuicktypeAppFeature]
    public let secondaryModuleTypes: [QuicktypeModuleType]
    public let sharingFlags: [QuicktypeProfileSharingFlag]

    public enum CodingKeys: String, CodingKey {
        case fingerprint = "fingerprint"
        case id = "id"
        case moduleTypes = "moduleTypes"
        case name = "name"
        case primaryModuleType = "primaryModuleType"
        case providerInfo = "providerInfo"
        case requiredFeatures = "requiredFeatures"
        case secondaryModuleTypes = "secondaryModuleTypes"
        case sharingFlags = "sharingFlags"
    }

    public init(fingerprint: String, id: String, moduleTypes: [QuicktypeModuleType], name: String, primaryModuleType: QuicktypeModuleType?, providerInfo: QuicktypeProviderInfo?, requiredFeatures: [QuicktypeAppFeature], secondaryModuleTypes: [QuicktypeModuleType], sharingFlags: [QuicktypeProfileSharingFlag]) {
        self.fingerprint = fingerprint
        self.id = id
        self.moduleTypes = moduleTypes
        self.name = name
        self.primaryModuleType = primaryModuleType
        self.providerInfo = providerInfo
        self.requiredFeatures = requiredFeatures
        self.secondaryModuleTypes = secondaryModuleTypes
        self.sharingFlags = sharingFlags
    }
}

public enum QuicktypeModuleType: String, Codable, Equatable, Sendable {
    case dns = "DNS"
    case httpProxy = "HTTPProxy"
    case ip = "IP"
    case onDemand = "OnDemand"
    case openVPN = "OpenVPN"
    case wireGuard = "WireGuard"
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProviderInfo
public struct QuicktypeProviderInfo: Codable, Equatable, Sendable {
    public let countryCode: String?
    public let providerID: String

    public enum CodingKeys: String, CodingKey {
        case countryCode = "countryCode"
        case providerID = "providerId"
    }

    public init(countryCode: String?, providerID: String) {
        self.countryCode = countryCode
        self.providerID = providerID
    }
}

public enum QuicktypeProfileSharingFlag: String, Codable, Equatable, Sendable {
    case shared = "shared"
    case tv = "tv"
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventSave
public struct QuicktypeProfileEventSave: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventStartRemoteImport
public struct QuicktypeProfileEventStartRemoteImport: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventStopRemoteImport
public struct QuicktypeProfileEventStopRemoteImport: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeTunnelEventDataCount
public struct QuicktypeTunnelEventDataCount: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeTunnelEventRefresh
public struct QuicktypeTunnelEventRefresh: Codable, Equatable, Sendable {
    public let active: [String: QuicktypeAppTunnelInfo]

    public enum CodingKeys: String, CodingKey {
        case active = "active"
    }

    public init(active: [String: QuicktypeAppTunnelInfo]) {
        self.active = active
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppTunnelInfo
public struct QuicktypeAppTunnelInfo: Codable, Equatable, Sendable {
    public let id: String
    public let onDemand: Bool
    public let status: QuicktypeAppTunnelStatus

    public enum CodingKeys: String, CodingKey {
        case id = "id"
        case onDemand = "onDemand"
        case status = "status"
    }

    public init(id: String, onDemand: Bool, status: QuicktypeAppTunnelStatus) {
        self.id = id
        self.onDemand = onDemand
        self.status = status
    }
}

public enum QuicktypeAppTunnelStatus: String, Codable, Equatable, Sendable {
    case connected = "connected"
    case connecting = "connecting"
    case disconnected = "disconnected"
    case disconnecting = "disconnecting"
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeVersionEventNew
public struct QuicktypeVersionEventNew: Codable, Equatable, Sendable {
    public let release: QuicktypeVersionRelease

    public enum CodingKeys: String, CodingKey {
        case release = "release"
    }

    public init(release: QuicktypeVersionRelease) {
        self.release = release
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeVersionRelease
public struct QuicktypeVersionRelease: Codable, Equatable, Sendable {
    public let url: String
    public let version: QuicktypeSemanticVersion

    public enum CodingKeys: String, CodingKey {
        case url = "url"
        case version = "version"
    }

    public init(url: String, version: QuicktypeSemanticVersion) {
        self.url = url
        self.version = version
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeSemanticVersion
public struct QuicktypeSemanticVersion: Codable, Equatable, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public enum CodingKeys: String, CodingKey {
        case major = "major"
        case minor = "minor"
        case patch = "patch"
    }

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeWebReceiverEventNewUpload
public struct QuicktypeWebReceiverEventNewUpload: Codable, Equatable, Sendable {
    public let file: QuicktypeWebFileUpload

    public enum CodingKeys: String, CodingKey {
        case file = "file"
    }

    public init(file: QuicktypeWebFileUpload) {
        self.file = file
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeWebFileUpload
public struct QuicktypeWebFileUpload: Codable, Equatable, Sendable {
    public let contents: String
    public let name: String

    public enum CodingKeys: String, CodingKey {
        case contents = "contents"
        case name = "name"
    }

    public init(contents: String, name: String) {
        self.contents = contents
        self.name = name
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeWebReceiverEventStart
public struct QuicktypeWebReceiverEventStart: Codable, Equatable, Sendable {
    public let website: QuicktypeWebsiteWithPasscode

    public enum CodingKeys: String, CodingKey {
        case website = "website"
    }

    public init(website: QuicktypeWebsiteWithPasscode) {
        self.website = website
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeWebsiteWithPasscode
public struct QuicktypeWebsiteWithPasscode: Codable, Equatable, Sendable {
    public let passcode: String?
    public let url: String

    public enum CodingKeys: String, CodingKey {
        case passcode = "passcode"
        case url = "url"
    }

    public init(passcode: String?, url: String) {
        self.passcode = passcode
        self.url = url
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeWebReceiverEventStop
public struct QuicktypeWebReceiverEventStop: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeWebReceiverEventUploadFailure
public struct QuicktypeWebReceiverEventUploadFailure: Codable, Equatable, Sendable {
    public let error: String

    public enum CodingKeys: String, CodingKey {
        case error = "error"
    }

    public init(error: String) {
        self.error = error
    }
}

public typealias QuicktypeTimestamp = String

// MARK: - Encode/decode helpers

public class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
            return true
    }

    public var hashValue: Int {
            return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if !container.decodeNil() {
                    throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
            }
    }

    public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
    }
}

final class JSONCodingKey: CodingKey {
    let key: String

    required init?(intValue: Int) {
            return nil
    }

    required init?(stringValue: String) {
            key = stringValue
    }

    var intValue: Int? {
            return nil
    }

    var stringValue: String {
            return key
    }
}

public class JSONAny: Codable, @unchecked Sendable {

    public let value: Any

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
            return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
            let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
            return EncodingError.invalidValue(value, context)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
            if let value = try? container.decode(Bool.self) {
                    return value
            }
            if let value = try? container.decode(Int64.self) {
                    return value
            }
            if let value = try? container.decode(Double.self) {
                    return value
            }
            if let value = try? container.decode(String.self) {
                    return value
            }
            if container.decodeNil() {
                    return JSONNull()
            }
            throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
            if let value = try? container.decode(Bool.self) {
                    return value
            }
            if let value = try? container.decode(Int64.self) {
                    return value
            }
            if let value = try? container.decode(Double.self) {
                    return value
            }
            if let value = try? container.decode(String.self) {
                    return value
            }
            if let value = try? container.decodeNil() {
                    if value {
                            return JSONNull()
                    }
            }
            if var container = try? container.nestedUnkeyedContainer() {
                    return try decodeArray(from: &container)
            }
            if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
                    return try decodeDictionary(from: &container)
            }
            throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
            if let value = try? container.decode(Bool.self, forKey: key) {
                    return value
            }
            if let value = try? container.decode(Int64.self, forKey: key) {
                    return value
            }
            if let value = try? container.decode(Double.self, forKey: key) {
                    return value
            }
            if let value = try? container.decode(String.self, forKey: key) {
                    return value
            }
            if let value = try? container.decodeNil(forKey: key) {
                    if value {
                            return JSONNull()
                    }
            }
            if var container = try? container.nestedUnkeyedContainer(forKey: key) {
                    return try decodeArray(from: &container)
            }
            if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
                    return try decodeDictionary(from: &container)
            }
            throw decodingError(forCodingPath: container.codingPath)
    }

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
            var arr: [Any] = []
            while !container.isAtEnd {
                    let value = try decode(from: &container)
                    arr.append(value)
            }
            return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
            var dict = [String: Any]()
            for key in container.allKeys {
                    let value = try decode(from: &container, forKey: key)
                    dict[key.stringValue] = value
            }
            return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
            for value in array {
                    if let value = value as? Bool {
                            try container.encode(value)
                    } else if let value = value as? Int64 {
                            try container.encode(value)
                    } else if let value = value as? Double {
                            try container.encode(value)
                    } else if let value = value as? String {
                            try container.encode(value)
                    } else if value is JSONNull {
                            try container.encodeNil()
                    } else if let value = value as? [Any] {
                            var container = container.nestedUnkeyedContainer()
                            try encode(to: &container, array: value)
                    } else if let value = value as? [String: Any] {
                            var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                            try encode(to: &container, dictionary: value)
                    } else {
                            throw encodingError(forValue: value, codingPath: container.codingPath)
                    }
            }
    }

    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
            for (key, value) in dictionary {
                    let key = JSONCodingKey(stringValue: key)!
                    if let value = value as? Bool {
                            try container.encode(value, forKey: key)
                    } else if let value = value as? Int64 {
                            try container.encode(value, forKey: key)
                    } else if let value = value as? Double {
                            try container.encode(value, forKey: key)
                    } else if let value = value as? String {
                            try container.encode(value, forKey: key)
                    } else if value is JSONNull {
                            try container.encodeNil(forKey: key)
                    } else if let value = value as? [Any] {
                            var container = container.nestedUnkeyedContainer(forKey: key)
                            try encode(to: &container, array: value)
                    } else if let value = value as? [String: Any] {
                            var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                            try encode(to: &container, dictionary: value)
                    } else {
                            throw encodingError(forValue: value, codingPath: container.codingPath)
                    }
            }
    }

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
            if let value = value as? Bool {
                    try container.encode(value)
            } else if let value = value as? Int64 {
                    try container.encode(value)
            } else if let value = value as? Double {
                    try container.encode(value)
            } else if let value = value as? String {
                    try container.encode(value)
            } else if value is JSONNull {
                    try container.encodeNil()
            } else {
                    throw encodingError(forValue: value, codingPath: container.codingPath)
            }
    }

    public required init(from decoder: Decoder) throws {
            if var arrayContainer = try? decoder.unkeyedContainer() {
                    self.value = try JSONAny.decodeArray(from: &arrayContainer)
            } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
                    self.value = try JSONAny.decodeDictionary(from: &container)
            } else {
                    let container = try decoder.singleValueContainer()
                    self.value = try JSONAny.decode(from: container)
            }
    }

    public func encode(to encoder: Encoder) throws {
            if let arr = self.value as? [Any] {
                    var container = encoder.unkeyedContainer()
                    try JSONAny.encode(to: &container, array: arr)
            } else if let dict = self.value as? [String: Any] {
                    var container = encoder.container(keyedBy: JSONCodingKey.self)
                    try JSONAny.encode(to: &container, dictionary: dict)
            } else {
                    var container = encoder.singleValueContainer()
                    try JSONAny.encode(to: &container, value: self.value)
            }
    }
}

extension QuicktypeAppFeature: CaseIterable {}
extension QuicktypeConfigFlag: CaseIterable {}
