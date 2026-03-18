// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension QuicktypeAppConstantsWebsites {
    public var apiURL: URL {
        homeURL.appending(path: "api")
    }

    public var faqURL: URL {
        homeURL.appending(path: "faq")
    }

    public var blogURL: URL {
        homeURL.appending(path: "blog")
    }

    public var disclaimerURL: URL {
        homeURL.appending(path: "disclaimer")
    }

    public var privacyPolicyURL: URL {
        homeURL.appending(path: "privacy")
    }

    public var donateURL: URL {
        homeURL.appending(path: "donate")
    }

    public var configURL: URL {
        homeURL.appending(path: "config/v1/bundle.json")
    }

    public var betaConfigURL: URL {
        homeURL.appending(path: "config/v1/bundle-beta.json")
    }
}

extension QuicktypeAppConstantsGitHub {
    public func urlForIssue(_ issue: Int) -> URL {
        issuesURL.appending(path: issue.description)
    }

    public func urlForChangelog(ofVersion version: String) -> URL {
        rawURL.appending(path: "refs/tags/v\(version)/CHANGELOG.txt")
    }
}

extension QuicktypeAppConstantsEmails {
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

extension QuicktypeAppConstantsTunnel {
    public func verificationDelayMinutes(isBeta: Bool) -> Int {
        let params = verificationParameters(isBeta: isBeta)
        return Int(params.delay / 60.0)
    }

    public func verificationParameters(isBeta: Bool) -> QuicktypeAppConstantsTunnelVerificationParameters {
        isBeta ? verification.beta : verification.production
    }
}

// FIXME: #1723, Precompute in Quicktype decoding
extension QuicktypeAppConstantsWebsites {
    public var homeURL: URL {
        URL(forceString: home, description: "websites.home")
    }

    public var appStoreDownloadURL: URL {
        URL(forceString: appStoreDownload, description: "websites.appStoreDownload")
    }

    public var eulaURL: URL {
        URL(forceString: eula, description: "websites.eula")
    }

    public var macDownloadURL: URL {
        URL(forceString: macDownload, description: "websites.macDownload")
    }

    public var subredditURL: URL {
        URL(forceString: subreddit, description: "websites.subreddit")
    }
}

// FIXME: #1723, Precompute in Quicktype decoding
extension QuicktypeAppConstantsGitHub {
    public var issuesURL: URL {
        URL(forceString: issues, description: "github.issues")
    }

    public var rawURL: URL {
        URL(forceString: raw, description: "github.raw")
    }

    public var latestReleaseURL: URL {
        URL(forceString: latestRelease, description: "github.latestRelease")
    }

    public var discussionsURL: URL {
        URL(forceString: discussions, description: "github.discussions")
    }
}
