// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// Partout
extension OpenAPIAppConstantsWebsites {
    public var blogURL: URL {
        partoutURL.appending(path: "blog")
    }

    public var donateURL: URL {
        partoutURL.appending(path: "donate")
    }

    public var apiURL: URL {
        partoutURL.appending(path: "passepartout-api")
    }

    public var configURL: URL {
        partoutURL.appending(path: "passepartout-config/v1/bundle.json")
    }

    public var betaConfigURL: URL {
        partoutURL.appending(path: "passepartout-config/v1/bundle-beta.json")
    }
}

// Passepartout
extension OpenAPIAppConstantsWebsites {
    public var disclaimerURL: URL {
        homeURL.appending(path: "disclaimer")
    }

    public var faqURL: URL {
        homeURL.appending(path: "faq")
    }

    public var privacyPolicyURL: URL {
        homeURL.appending(path: "privacy")
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
