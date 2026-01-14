// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1594, Make internal
import Partout

extension ProfileType where UserInfoType == JSON {
    public var attributes: ProfileAttributes {
        ProfileAttributes(userInfo: userInfo)
    }
}

extension MutableProfileType where UserInfoType == JSON {
    public var attributes: ProfileAttributes {
        get {
            ProfileAttributes(userInfo: userInfo)
        }
        set {
            userInfo = newValue.userInfo
        }
    }
}

// MARK: - ProfileAttributes

public struct ProfileAttributes {
    fileprivate enum Key: String {
        case fingerprint

        case lastUpdate

        case isAvailableForTV

        case preferences
    }

    private(set) var userInfo: JSON

    init(userInfo: JSON?) {
        self.userInfo = userInfo ?? [:]
    }
}

// MARK: Basic

extension ProfileAttributes {
    public var fingerprint: UUID? {
        get {
            guard let string = userInfo[Key.fingerprint.rawValue]?.stringValue else {
                return nil
            }
            return UUID(uuidString: string)
        }
        set {
            userInfo[Key.fingerprint.rawValue] = newValue.map {
                .string($0.uuidString)
            }
        }
    }

    public var lastUpdate: Date? {
        get {
            guard let interval = userInfo[Key.lastUpdate.rawValue]?.doubleValue else {
                return nil
            }
            return Date(timeIntervalSinceReferenceDate: interval)
        }
        set {
            userInfo[Key.lastUpdate.rawValue] = newValue.map {
                .number($0.timeIntervalSinceReferenceDate)
            }
        }
    }

    public var isAvailableForTV: Bool? {
        get {
            userInfo[Key.isAvailableForTV.rawValue]?.boolValue
        }
        set {
            userInfo[Key.isAvailableForTV.rawValue] = newValue.map {
                .bool($0)
            }
        }
    }
}

// MARK: Preferences

extension ProfileAttributes {
    public func preferences(inModule moduleId: UUID) -> ModulePreferences {
        ModulePreferences(userInfo: allPreferences[moduleId.uuidString])
    }

    public mutating func setPreferences(_ module: ModulePreferences, inModule moduleId: UUID) {
        allPreferences[moduleId.uuidString] = module.userInfo
    }

    public func preference<T>(inModule moduleId: UUID, block: (ModulePreferences) -> T) -> T? {
        let module = preferences(inModule: moduleId)
        return block(module)
    }

    public mutating func editPreferences(inModule moduleId: UUID, block: (inout ModulePreferences) -> Void) {
        var module = preferences(inModule: moduleId)
        block(&module)
        setPreferences(module, inModule: moduleId)
    }
}

private extension ProfileAttributes {
    var allPreferences: [String: JSON] {
        get {
            userInfo[Key.preferences.rawValue]?.objectValue ?? [:]
        }
        set {
            userInfo[Key.preferences.rawValue] = .object(newValue)
        }
    }
}

// MARK: -

extension ProfileAttributes: CustomDebugStringConvertible {
    public var debugDescription: String {
        let descs = [
            fingerprint.map {
                "fingerprint: \($0)"
            },
            lastUpdate.map {
                "lastUpdate: \($0)"
            },
            isAvailableForTV.map {
                "isAvailableForTV: \($0)"
            },
            "allPreferences: \(allPreferences)"
        ].compactMap { $0 }

        return "{\(descs.joined(separator: ", "))}"
    }
}
