// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Dispatch

#if !PSP_CROSS
extension ConfigManager: ObservableObject {}
#endif

@MainActor
public final class ConfigManager {
    private let queue = DispatchQueue(label: "ConfigManager")

    private let strategy: ConfigManagerStrategy?

    private let buildNumber: Int

    private var bundle: ABI.ConfigBundle? {
        willSet {
#if !PSP_CROSS
            objectWillChange.send()
#endif
        }
        didSet {
            // Take a snapshot of the active flags
            queue.sync {
                synchronousActiveFlags = Set(ABI.ConfigFlag.allCases.filter {
                    isActive($0)
                })
            }
        }
    }

    nonisolated(unsafe)
    private var synchronousActiveFlags: Set<ABI.ConfigFlag> = []

    private var isPending = false

    public init() {
        strategy = nil
        buildNumber = .max // Activate flags regardless of .minBuild
    }

    public init(strategy: ConfigManagerStrategy, buildNumber: Int) {
        self.strategy = strategy
        self.buildNumber = buildNumber
    }

    // TODO: #1447, handle 0-100 deployment values with local random value
    public func refreshBundle() async {
        guard let strategy else {
            return
        }
        guard !isPending else {
            return
        }
        isPending = true
        defer {
            isPending = false
        }
        do {
            pp_log_g(.App.core, .debug, "Config: refreshing bundle...")
            let newBundle = try await strategy.bundle()
            bundle = newBundle
            let activeFlags = newBundle.activeFlags(withBuild: buildNumber)
            pp_log_g(.App.core, .info, "Config: active flags = \(activeFlags)")
            pp_log_g(.App.core, .debug, "Config: \(newBundle)")
        } catch ABI.AppError.rateLimit {
            pp_log_g(.App.core, .debug, "Config: TTL")
        } catch {
            pp_log_g(.App.core, .error, "Unable to refresh config flags: \(error)")
        }
    }

    public func isActive(_ flag: ABI.ConfigFlag) -> Bool {
        activeMap(for: flag) != nil
    }

    public func data(for flag: ABI.ConfigFlag) -> JSON? {
        activeMap(for: flag)?.data
    }

    public nonisolated var activeFlags: Set<ABI.ConfigFlag> {
        queue.sync {
            synchronousActiveFlags
        }
    }
}

private extension ConfigManager {
    func activeMap(for flag: ABI.ConfigFlag) -> ABI.ConfigBundle.Config? {
        guard let map = bundle?.map[flag] else {
            return nil
        }
        guard map.isActive(withBuild: buildNumber) else {
            return nil
        }
        return map
    }
}
