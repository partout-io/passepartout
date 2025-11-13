// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout

// WARNING: beware of Resources.constants dependency

extension BundleConfiguration {
    public static var urlForAppLog: URL {
        urlForCaches.appending(path: Resources.constants.log.appPath)
    }

    public static func urlForTunnelLog(in target: DistributionTarget) -> URL {
        let baseURL: URL
        if target.supportsAppGroups {
            baseURL = urlForCaches
        } else {
            let fm: FileManager = .default
            baseURL = fm.temporaryDirectory
            do {
                try fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
            } catch {
                pp_log_g(.App.core, .error, "Unable to create temporary directory \(baseURL): \(error)")
            }
        }
        return baseURL.appending(path: Resources.constants.log.tunnelPath)
    }
}

// App Group container is not available on tvOS (#1007)

#if !os(tvOS)

extension BundleConfiguration {
    public static var urlForCaches: URL {
        let url = appGroupURL.appending(components: "Library", "Caches")
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            pp_log_g(.App.core, .fault, "Unable to create group caches directory: \(error)")
        }
        return url
    }

    public static var urlForDocuments: URL {
        let url = appGroupURL.appending(components: "Library", "Documents")
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            pp_log_g(.App.core, .fault, "Unable to create group documents directory: \(error)")
        }
        return url
    }
}

private extension BundleConfiguration {
    static var appGroupURL: URL {
        let groupId = mainString(for: .groupId)
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
            pp_log_g(.App.core, .error, "Unable to access App Group container")
            return FileManager.default.temporaryDirectory
        }
        return url
    }
}

#else

extension BundleConfiguration {
    public static var urlForCaches: URL {
        do {
            return try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            pp_log_g(.App.core, .fault, "Unable to create user documents directory: \(error)")
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }

    public static var urlForDocuments: URL {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            pp_log_g(.App.core, .fault, "Unable to create user documents directory: \(error)")
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }
}

#endif
