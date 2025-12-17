// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public final class SystemExtensionManager: NSObject, ExtensionInstaller, @unchecked Sendable {
    private let queue: DispatchQueue

    fileprivate let identifier: String

    fileprivate let version: String

    fileprivate let build: Int

    private var result: ExtensionInstallerResult

    private var isPending: Bool

    private var pendingContinuation: CheckedContinuation<ExtensionInstallerResult, Error>?

    public init(identifier: String, version: String, build: Int) {
        queue = DispatchQueue(label: "SystemExtensionManager")
        self.identifier = identifier
        self.version = version
        self.build = build
        result = .unknown
        isPending = false
    }

#if !os(macOS)
    public var currentResult: ExtensionInstallerResult {
        .unknown
    }
#endif
}

#if os(macOS)

import SystemExtensions

extension SystemExtensionManager {
    public var currentResult: ExtensionInstallerResult {
        queue.sync {
            result
        }
    }

    public func load() async throws -> ExtensionInstallerResult {
        queue.sync {
            guard !isPending else {
                assertionFailure("Loading twice: \(identifier)")
                return
            }
            isPending = true
        }

        let request: OSSystemExtensionRequest = .propertiesRequest(
            forExtensionWithIdentifier: identifier,
            queue: .main
        )
        request.delegate = self

        let result = try await withCheckedThrowingContinuation { continuation in
            pendingContinuation = continuation
            OSSystemExtensionManager.shared.submitRequest(request)
        }

        queue.sync {
            isPending = false
        }
        return result
    }

    public func install() async throws -> ExtensionInstallerResult {
        queue.sync {
            guard !isPending else {
                assertionFailure("Installing twice: \(identifier)")
                return
            }
            isPending = true
        }

        let request: OSSystemExtensionRequest = .activationRequest(
            forExtensionWithIdentifier: identifier,
            queue: .main
        )
        request.delegate = self

        let result = try await withCheckedThrowingContinuation { continuation in
            pendingContinuation = continuation
            OSSystemExtensionManager.shared.submitRequest(request)
        }

        queue.sync {
            isPending = false
        }
        return result
    }
}

extension SystemExtensionManager: OSSystemExtensionRequestDelegate {
    public func request(_ request: OSSystemExtensionRequest, foundProperties properties: [OSSystemExtensionProperties]) {
        NSLog("SystemExtensionManager: self = {\(identifier) \(version) \(build)}")
        NSLog("SystemExtensionManager: found properties")
        let sortedProperties = properties.sorted(by: OSSystemExtensionProperties.sorted)
        sortedProperties.forEach {
            NSLog("\t\($0.localDescription)")
        }
        let matching = sortedProperties
            .filter {
                $0.matches(self)
            }
            .first // sorting implies that .first is .max
        guard let matching else {
            reportResult(.unknown)
            return
        }
        NSLog("SystemExtensionManager: matching = \(matching.localDescription)")
        let result: ExtensionInstallerResult = matching.isAwaitingUserApproval ? .needsApproval : matching.isEnabled ? .success : .unknown
        reportResult(result)
    }

    public func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        .replace
    }

    public func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        reportResult(.success)
    }

    public func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        reportResult(.needsApproval)
    }

    public func requestRequiresRestart(_ request: OSSystemExtensionRequest) {
        reportResult(.requiresRestart)
    }

    public func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        reportError(error)
    }
}

private extension SystemExtensionManager {
    func reportResult(_ result: ExtensionInstallerResult) {
        guard let continuation = pendingContinuation else {
            return
        }
        self.result = result
        continuation.resume(returning: result)
        pendingContinuation = nil
    }

    func reportError(_ error: Error) {
        guard let continuation = pendingContinuation else {
            return
        }
        result = .unknown
        continuation.resume(throwing: error)
        pendingContinuation = nil
    }
}

private extension OSSystemExtensionProperties {
    static func sorted(lhs: OSSystemExtensionProperties, rhs: OSSystemExtensionProperties) -> Bool {
        lhs.rank < rhs.rank
    }

    func matches(_ manager: SystemExtensionManager) -> Bool {
        bundleIdentifier == manager.identifier &&
        bundleShortVersion == manager.version &&
        bundleVersion == "\(manager.build)"
    }

    var rank: Int {
        if isEnabled {
            return .min
        } else if isAwaitingUserApproval {
            return 1
        } else {
            return .max
        }
    }

    var localDescription: String {
        "{\(bundleIdentifier) \(bundleShortVersion) \(bundleVersion), isEnabled=\(isEnabled), isAwaitingUserApproval=\(isAwaitingUserApproval), url=\(url)}"
    }
}

#else

extension SystemExtensionManager {
    public func load() async throws -> ExtensionInstallerResult {
        assertionFailure("SystemExtensionManager called on non-macOS")
        return .unknown
    }

    public func install() async throws -> ExtensionInstallerResult {
        assertionFailure("SystemExtensionManager called on non-macOS")
        return .unknown
    }
}

#endif
