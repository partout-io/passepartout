// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension TimeInterval: StyledLocalizableEntity {
    public enum Style {
        case timeString
    }

    public func localizedDescription(style: Style) -> String {
        switch style {
        case .timeString:
            if self > 0 {
                return asTimeString
            } else {
                return Strings.Global.Nouns.disabled
            }
        }
    }
}

extension Date: StyledLocalizableEntity {
    public enum Style {
        case timestamp
    }

    public func localizedDescription(style: Style) -> String {
        switch style {
        case .timestamp:
            return Self.timestampFormatter.string(from: self)
        }
    }

    private static let timestampFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .medium
        return fmt
    }()
}

extension UUID {
    public var flatString: String {
        let str = uuidString.replacingOccurrences(of: "-", with: "")
        assert(str.count == 32)
        return str
    }
}

extension String: StyledLocalizableEntity {
    public enum Style {
        case quartets
    }

    public func localizedDescription(style: Style) -> String {
        switch style {
        case .quartets:
            return matrix(of: 4, each: 4)
        }
    }

    private func matrix(of word: Int, each: Int, _ columnSeparator: String = " ", _ rowSeparator: String = "\n") -> String {
        var groups: [[String]] = []
        var currentGroup: [String] = []
        var currentString: [Character] = []
        var i = 0
        var j = 0
        for ch in self {
            currentString.append(ch)
            i = (i + 1) % word
            if i == 0 {
                currentGroup.append(String(currentString))
                currentString = []

                j = (j + 1) % each
                if j == 0 {
                    groups.append(currentGroup)
                    currentGroup = []
                }
            }
        }
        return groups
            .map {
                $0.joined(separator: columnSeparator)
            }
            .joined(separator: rowSeparator)
    }
}

extension Int {
    public var localizedEntries: String? {
        switch self {
        case 0: return nil
        case 1: return Strings.Global.Nouns.entriesOne
        default: return Strings.Global.Nouns.entriesN(self)
        }
    }
}
