// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_ABI
import CommonLibrary_C
import Partout

extension ABI {
    // Following psp_completion:
    //
    // Code == 0 -> Success, String = JSON payload
    // Code != 0 -> Failure, Optional Error
    typealias RunCallback = @Sendable (
        _ code: Int32,
        _ payload: String?,
        _ error: Error?
    ) -> Void

    // Run ABI initialization synchronously.
    //
    // WARNING: This method is potentially DANGEROUS and fights Concurrency
    // only to simplify the app initialization flow. Any other ABI function
    // MUST NEVER block the current thread. Use run() variants instead.
    //
    static func runBlockingInitialization(
        _ block: @escaping @Sendable @BusinessActor () async -> Int32
    ) -> Int32 {
        let isBusinessRunningOnMainThread = BusinessActor.self == MainActor.self
        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var result = PSPCompletionCodeFailure
        Task { @Sendable @BusinessActor in
            result = await block()
            semaphore.signal()
        }
#if canImport(Darwin)
        // Business code runs on MainActor on macOS
        guard isBusinessRunningOnMainThread else {
            fatalError("Apple BusinessActor must be MainActor")
        }
        // Yield the main thread otherwise the block() invocation may deadlock
        // on the first async call to business objects, as they run on MainActor
        let isMainThread = pthread_main_np() == 1
        if isMainThread {
            let yield = 0.001
            while semaphore.wait(timeout: .now()) == .timedOut {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: yield))
            }
            return result
        }
#else
        // Ensure that non-Apple business runs off of MainActor
        // because other UI engines may lock the main thread
        guard !isBusinessRunningOnMainThread else {
            fatalError("Non-Apple BusinessActor must not be MainActor")
        }
#endif
        semaphore.wait()
        return result
    }

    // Run ABI function without waiting for completion
    static func run(
        _ block: @escaping @Sendable @BusinessActor () async -> Void
    ) {
        Task { @Sendable @BusinessActor in
            await block()
        }
    }

    // Run ABI function with a completion callback. The consumer must call
    // the RunCallback block argument to invoke completion with a return code.
    static func run(
        _ completion: psp_completion,
        _ block: @escaping @Sendable @BusinessActor (RunCallback?) async -> Void
    ) {
        nonisolated(unsafe) let completion = completion
        Task { @Sendable @BusinessActor in
            let runCallback: RunCallback?
            if let cb = completion.callback {
                runCallback = { code, result, error in
                    let payload: String?
                    if let error {
                        payload = try? ABI.encodeJSON(AppError(error))
                    } else {
                        payload = result
                    }
                    cb(completion.ctx, code, payload)
                }
            } else {
                runCallback = nil
            }
            await block(runCallback)
        }
    }
}

extension ABI.AppError: Encodable {
    private enum CodingKeys: CodingKey {
        case code
        case description
    }

    public var code: ABI.AppErrorCode {
        switch self {
        case .binaryFile:
            return .binaryFile
        case .corruptProviderModule:
            return .corruptProviderModule
        case .couldNotLaunch:
            return .couldNotLaunch
        case .emptyProducts:
            return .emptyProducts
        case .emptyProfileName:
            return .emptyProfileName
        case .encoding:
            return .encoding
        case .importError:
            return .importError
        case .incompatibleModules:
            return .incompatibleModules
        case .incompleteModule:
            return .incompleteModule
        case .ineligibleProfile:
            return .ineligibleProfile
        case .interactiveLogin:
            return .interactiveLogin
        case .invalidField:
            return .invalidField
        case .malformedModule:
            return .malformedModule
        case .missingProviderEntity:
            return .missingProviderEntity
        case .moduleRequiresConnection:
            return .moduleRequiresConnection
        case .noActiveModules:
            return .noActiveModules
        case .notFound:
            return .notFound
        case .openVPNPassphraseRequired:
            return .openVPNPassphraseRequired
        case .openVPNUnsupportedCompression:
            return .openVPNUnsupportedCompression
        case .other:
            return .other
        case .partout:
            return .partout
        case .permissionDenied:
            return .permissionDenied
        case .rateLimit:
            return .rateLimit
        case .systemExtension:
            return .systemExtension
        case .timeout:
            return .timeout
        case .unexpectedResponse:
            return .unexpectedResponse
        case .urlRequestFailed:
            return .urlRequestFailed
        case .urlRequestUnavailable:
            return .urlRequestUnavailable
        case .verificationReceiptIsLoading:
            return .verificationReceiptIsLoading
        case .verificationRequiredFeatures:
            return .verificationRequiredFeatures
        case .webReceiver:
            return .webReceiver
        case .webUploader:
            return .webUploader
        case .wireGuardEmptyPeers:
            return .wireGuardEmptyPeers
        }
    }

    public var localizedDescription: String? {
        switch self {
        case .importError(let message):
            return message
        default:
            return nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encodeIfPresent(localizedDescription, forKey: .description)
    }
}

extension ABI {
    // Wrap ABI.Event in a format that decodes cross-platform
    struct EventWrapper: Encodable {
        private let payload: Encodable

        init?(_ event: Event) {
            guard let payload = Self.payload(of: event) else { return nil }
            self.payload = payload
        }

        func encode(to encoder: Encoder) throws {
            try payload.encode(to: encoder)
        }

        // Return the first (and only) associated value of the enum
        private static func payload(of event: Event) -> Encodable? {
            let mirror = Mirror(reflecting: event)
            guard let arg = mirror.children.first else { return nil }
            let children = Mirror(reflecting: arg.value).children
            assert(children.count == 1)
            guard let payload = children.first?.value else { return nil }
            return payload as? Encodable
        }
    }
}

extension AppPreferencesStore {
    static func fromData(_ data: Data?) -> AppPreferencesStore {
        let values: ABI.AppPreferences
        if let data {
            do {
                values = try ABI.decode(ABI.AppPreferences.self, from: data)
            } catch {
                pspLog(.abi, .error, "Unable to decode preferences: \(error)")
                values = .default()
            }
        } else {
            pspLog(.abi, .info, "No preferences provided")
            values = .default()
        }
        return AppPreferencesStore(values)
    }
}

// Shortcut to convert a C string to JSON data
extension UnsafePointer where Pointee == CChar {
    var asJSONData: Data? {
        String(cString: self).data(using: .utf8)
    }
}
#endif
