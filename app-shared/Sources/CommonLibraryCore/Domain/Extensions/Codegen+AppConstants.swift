// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension OpenAPIAppConstantsWebsites {
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

extension OpenAPIAppConstantsGithub {
    public func urlForIssue(_ issue: Int) -> URL {
        issuesURL.appending(path: issue.description)
    }

    public func urlForChangelog(ofVersion version: String) -> URL {
        rawURL.appending(path: "refs/tags/v\(version)/CHANGELOG.txt")
    }
}

extension OpenAPIAppConstantsEmails {
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

extension OpenAPIAppConstantsTunnel {
    public func verificationDelayMinutes(isBeta: Bool) -> Int {
        let params = verificationParameters(isBeta: isBeta)
        return Int(params.delay / 60.0)
    }

    public func verificationParameters(isBeta: Bool) -> OpenAPIAppConstantsTunnelVerificationParameters {
        isBeta ? verification.beta : verification.production
    }
}

extension OpenAPIAppConstantsTunnelVerificationParameters {
    public var delay: Double {
#if os(tvOS)
        tvDelay ?? defaultDelay
#else
        defaultDelay
#endif
    }
}
