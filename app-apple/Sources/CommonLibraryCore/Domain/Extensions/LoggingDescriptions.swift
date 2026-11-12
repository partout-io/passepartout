// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI.AppProfileHeader: CustomStringConvertible {
    public var description: String {
        if PartoutLogger.default.logsModules, let json = try? ABI.encodeJSON(self) {
            return json
        }
        return "ProfileHeader(id=\(id), modules=\(moduleTypes.map(\.rawValue)), sharing=\(sharingFlags.map(\.rawValue).sorted()), features=\(requiredFeatures.map(\.rawValue).sorted()))"
    }
}

extension OpenAPIAppProfileHeader: CustomStringConvertible {
    public var description: String {
        if PartoutLogger.default.logsModules, let json = try? ABI.encodeJSON(self) {
            return json
        }
        return "ProfileHeader(id=\(id), modules=\(moduleTypes.map(\.rawValue)), sharing=\(sharingFlags.map(\.rawValue).sorted()), features=\(requiredFeatures.map(\.rawValue).sorted()))"
    }
}

extension ABI.AppTunnelInfo: CustomStringConvertible {
    public var description: String {
        if PartoutLogger.default.logsModules, let json = try? ABI.encodeJSON(self) {
            return json
        }
        return "TunnelInfo(id=\(id), status=\(status.rawValue), onDemand=\(onDemand), lastError=\(lastErrorCode ?? "none"))"
    }
}

extension ABI.AppFeature: CustomStringConvertible {
    public var description: String { rawValue }
}

extension ABI.ProfileSharingFlag: CustomStringConvertible {
    public var description: String { rawValue }
}

extension ABI.ProfileEvent: CustomStringConvertible {
    public var description: String {
        if PartoutLogger.default.logsModules, let json = try? ABI.encodeJSON(self) {
            return json
        }
        return switch self {
        case .ready: "ready"
        case .localProfiles: "localProfiles"
        case .refresh(let payload): "refresh(headers=\(payload.headers.count))"
        case .save(let payload): "save(id=\(payload.profile.id))"
        case .delete(let payload): "delete(count=\(payload.ids.count))"
        case .startRemoteImport: "startRemoteImport"
        case .stopRemoteImport: "stopRemoteImport"
        case .changeRemoteImporting(let payload): "remoteImporting(enabled=\(payload.isImporting))"
        }
    }
}

extension ABI.ConfigEvent: CustomStringConvertible {
    public var description: String {
        if PartoutLogger.default.logsModules, let json = try? ABI.encodeJSON(self) {
            return json
        }
        return switch self {
        case .refresh(let payload): "refresh(flags=\(payload.flags.count), dataEntries=\(payload.data.count))"
        }
    }
}

extension ConfigBundle: CustomStringConvertible {
    public var description: String {
        if PartoutLogger.default.logsModules, let json = try? ABI.encodeJSON(self) {
            return json
        }
        return "ConfigBundle(flags=\(map.keys.map(\.rawValue).sorted()), dataEntries=\(map.values.filter { $0.data != nil }.count))"
    }
}

extension OpenAPIConfigBundleConfig: CustomStringConvertible {
    public var description: String {
        if PartoutLogger.default.logsModules, let json = try? ABI.encodeJSON(self) {
            return json
        }
        return "Config(rate=\(rate), minBuild=\(minBuild.map(String.init) ?? "none"), hasData=\(data != nil))"
    }
}
